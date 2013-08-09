# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'
require 'ipaddress'
require 'yaml'

module Dcmgr
  module Rpc
    class HvaHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper
      include Dcmgr::Helpers::BlockDeviceHelper

      def attach_volume_to_host
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        tryagain do
          next true if File.exist?(@os_devpath)

          sh("iscsiadm -m discovery -t sendtargets -p %s", [@vol[:storage_node][:ipaddr]])
          sh("iscsiadm -m node -l -T '%s' --portal '%s'",
             [@vol[:transport_information][:iqn], @vol[:storage_node][:ipaddr]])
          # wait udev queue
          sh("/sbin/udevadm settle")
        end

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attaching,
                      :attached_at => nil,
                      :instance_id => @inst[:id], # needed after cleanup
                      :host_device_name => @os_devpath}) do |req|
          req.oneshot = true
        end
      end

      def detach_volume_from_host(volume)
        if volume[:volume_type] == 'Dcmgr::Models::IscsiVolume'
          # iscsi logout
          sh("iscsiadm -m node -T '%s' --logout", [volume[:volume_device][:iqn]])
          # wait udev queue
          sh("/sbin/udevadm settle")
        end
      end

      def update_volume_state_to_available
        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:available,
                      :host_device_name=>nil,
                      :instance_id=>nil,
                      :detached_at => Time.now.utc,
                    }) do |req|
          req.oneshot = true
        end
        event.publish('hva/volume_detached', :args=>[@inst_id, @vol_id])
      end

      def delete_local_volume(volume)
        if @hva_ctx.nil?
          logger.warn("Skip delte_local_volume since hva context is unset.")
          return
        end
        
        return unless volume[:is_local_volume]

        task_session.invoke(Drivers::LocalStore.driver_class(@inst[:host_node][:hypervisor]),
                            :delete_volume, [@hva_ctx, volume])
        update_volume_state(volume[:uuid], {:state=>:deleted, :deleted_at=>Time.now.utc},
                            'hva/volume_deleted')
      end
      
      def delete_all_local_volumes
        @inst[:volume].values.each { |v|
          ignore_error do
            delete_local_volume(v)
          end
        }
      end
      
      # This method can be called sometime when the instance variables
      # are also failed to be set. They need to be checked before looked
      # up.
      def terminate_instance(state_update=false)
        if @hva_ctx.nil?
          logger.warn("Skip delte_local_volume since hva context is unset.")
          return
        end
        
        ignore_error {
          task_session.invoke(@hva_ctx.hypervisor_driver_class,
                              :terminate_instance, [@hva_ctx])
        }

        @inst[:volume].each { |volid, v|
          ignore_error {
            if v[:is_local_volume]
              delete_local_volume(v)
            else
              # force to continue detaching volumes during termination.
              ignore_error { detach_volume_from_host(v) }
              if state_update
                update_volume_state_to_available(volid) rescue @hva_ctx.logger.error($!)
              end
            end
          }
        }

        # cleanup vm data folder
        ignore_error {
          unless @hva_ctx.hypervisor_driver_class == Dcmgr::Drivers::ESXi
            FileUtils.rm_r(File.expand_path("#{@inst_id}", Dcmgr.conf.vm_data_dir))
          end
        }
      end

      def update_state_file(state)
        # Insert state file in the tmp directory for the recovery script to use
        @hva_ctx.dump_instance_parameter('state', state)
      end

      def update_instance_state(opts, ev=nil)
        raise "Can't update instance info without setting @inst_id" if @inst_id.nil?
        rpc.request('hva-collector', 'update_instance', @inst_id, opts) do |req|
          req.oneshot = true
        end
        if ev
          ev = [ev] unless ev.is_a? Array
          ev.each { |e|
            event.publish(e, :args=>[@inst_id])
          }
        end

        update_state_file(opts[:state]) unless opts[:state].nil?
      end

      def finalize_instance
        raise "Can't update instance info without setting @inst_id" if @inst_id.nil?

        # Security group vnic left events for vnet netfilter
        destroy_instance_vnics(@inst)

        rpc.request("hva-collector", 'finalize_instance', @inst_id, Time.now.utc)

        ev = ['hva/instance_terminated',"#{@inst[:host_node][:node_id]}/instance_terminated"]
        ev.each { |e|
          event.publish(e, :args=>[@inst_id])
        }
      end

      def update_instance_state_to_terminated(opts)
        raise "Can't update instance info without setting @inst_id" if @inst_id.nil?
        
        # syncronized
        rpc.request('hva-collector', 'update_instance', @inst_id, opts)
        
        ev = ['hva/instance_terminated',"#{@inst[:host_node][:node_id]}/instance_terminated"]
        ev.each { |e|
          event.publish(e, :args=>[@inst_id])
        }
        
        # Security group vnic left events for vnet netfilter
        destroy_instance_vnics(@inst)
        
        @inst[:volume].values.each { |v|
          rpc.request('sta-collector', 'update_volume', v[:uuid], {
                        :state=>:deleted,
                        :host_device_name=>nil,
                        :instance_id=>nil,
                        :detached_at => Time.now.utc,
                      })
          event.publish('hva/volume_deleted', :args=>[v[:uuid]])
        }
      end

      def create_instance_vnics(inst)
        inst[:vif].each { |vnic|
          event.publish("#{@inst[:host_node][:node_id]}/vnic_created", :args=>[vnic[:uuid]])

          vnic[:security_groups].each { |secg|
            event.publish("#{secg}/vnic_joined", :args=>[vnic[:uuid]])
          }
        }
      end

      def destroy_instance_vnics(inst)
        inst[:vif].each { |vnic|
          event.publish("#{@inst[:host_node][:node_id]}/vnic_destroyed", :args=>[vnic[:uuid]])
          vnic[:security_groups].each { |secg|
            event.publish("#{secg}/vnic_left", :args=>[vnic[:uuid]])
          }
        }
      end

      def update_volume_state(vol_id, opts, ev)
        raise "Can't update volume parameter" if vol_id.nil?
        rpc.request('sta-collector', 'update_volume', vol_id, opts) do |req|
          req.oneshot = true
        end
        event.publish(ev, :args=>[@vol_id])
      end

      def check_interface
        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :check_interface, [@hva_ctx])
      end

      def attach_vnic_to_port
        sh("/sbin/ip link set %s up", [@nic_id])
        sh("#{Dcmgr.conf.brctl_path} addif %s %s", [@bridge, @nic_id])
      end

      def detach_vnic_from_port
        sh("/sbin/ip link set %s down", [@nic_id])
        sh("#{Dcmgr.conf.brctl_path} delif %s %s", [@bridge, @nic_id])
      end

      def get_linux_dev_path
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        @os_devpath = "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{@vol[:storage_node][:ipaddr]}:3260",
                                                                      @vol[:transport_information][:iqn],
                                                                      @vol[:transport_information][:lun]]
      end

      def setup_metadata_drive
        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :setup_metadata_drive, [@hva_ctx, get_metadata_items])
        # export as single yaml file.
        @hva_ctx.dump_instance_parameter('metadata.yml', YAML.dump(get_metadata_items))
       end

      def get_metadata_items
        vnic = @inst[:instance_nics].first

        # Appendix B: Metadata Categories
        # http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?AESDG-chapter-instancedata.html
        metadata_items = {
          'ami-id' => @inst[:image][:uuid],
          'ami-launch-index' => 0,
          'ami-manifest-path' => nil,
          'ancestor-ami-ids' => nil,
          'block-device-mapping/root' => '/dev/sda',
          'hostname' => @inst[:hostname],
          'instance-action' => @inst[:state],
          'instance-id' => @inst[:uuid],
          'instance-type' => @inst[:request_params][:instance_spec_id] || @inst[:image][:instance_model_name],
          'kernel-id' => nil,
          'local-hostname' => @inst[:hostname],
          'local-ipv4' => @inst[:ips].first,
          'mac' => vnic ? vnic[:mac_addr].unpack('A2'*6).join(':') : nil,
          'placement/availability-zone' => nil,
          'product-codes' => nil,
          'public-hostname' => @inst[:hostname],
          'public-ipv4'    => @inst[:nat_ips].first,
          'ramdisk-id' => nil,
          'reservation-id' => nil,
          'x-account-id' => @inst[:account_id]
        }

        @inst[:vif].each { |vnic|
          next if vnic[:ipv4].nil? or vnic[:ipv4][:network].nil?

          netaddr  = IPAddress::IPv4.new("#{vnic[:ipv4][:network][:ipv4_network]}/#{vnic[:ipv4][:network][:prefix]}")

          # vfat doesn't allow folder name including ":".
          # folder name including mac address replaces "-" to ":".
          mac = vnic[:mac_addr].unpack('A2'*6).join('-')
          metadata_items.merge!({
            "network/interfaces/macs/#{mac}/local-hostname" => @inst[:hostname],
            "network/interfaces/macs/#{mac}/local-ipv4s" => vnic[:ipv4][:address],
            "network/interfaces/macs/#{mac}/mac" => vnic[:mac_addr].unpack('A2'*6).join(':'),
            "network/interfaces/macs/#{mac}/public-hostname" => @inst[:hostname],
            "network/interfaces/macs/#{mac}/public-ipv4s" => vnic[:ipv4][:nat_address],
            "network/interfaces/macs/#{mac}/security-groups" => vnic[:security_groups].join(' '),
            # wakame-vdc extention items.
            # TODO: need an iface index number?
            "network/interfaces/macs/#{mac}/x-dns" => vnic[:ipv4][:network][:dns_server],
            "network/interfaces/macs/#{mac}/x-gateway" => vnic[:ipv4][:network][:ipv4_gw],
            "network/interfaces/macs/#{mac}/x-netmask" => netaddr.prefix.to_ip.to_s,
            "network/interfaces/macs/#{mac}/x-network" => vnic[:ipv4][:network][:ipv4_network],
            "network/interfaces/macs/#{mac}/x-broadcast" => netaddr.broadcast.to_s,
            "network/interfaces/macs/#{mac}/x-metric" => vnic[:ipv4][:network][:metric],
          })
        }
        if @inst[:ssh_key_data]
          metadata_items.merge!({
            "public-keys/0=#{@inst[:ssh_key_data][:uuid]}" => @inst[:ssh_key_data][:public_key],
            'public-keys/0/openssh-key'=> @inst[:ssh_key_data][:public_key],
          })
        else
          metadata_items.merge!({'public-keys/'=>nil})
        end
      end

      # syntax sugar to catch any errors and continue to work the code
      # following.
      def ignore_error(&blk)
        begin
          blk.call
        rescue ::Exception => e
          @hva_ctx.logger.error("Ignoring error: #{e.class.to_s} #{e.message} from #{e.backtrace.first}")
        end
      end

      # Reset TaskSession per request.
      def task_session
        @task_session ||= begin
                            Task::TaskSession.reset!(:thread)
                            Task::TaskSession.current[:logger] = @hva_ctx.logger

                            Task::TaskSession.current
                          end
      end

      def wait_volumes_available
        if @inst[:volume].values.all?{|v| v[:state] == 'available'}
          # boot instance becase all volumes are ready.
          job.submit("hva-handle.#{node.node_id}", 'run_local_store', @inst[:uuid])
        elsif @inst[:state] == 'terminated' || @inst[:volume].values.find{|v| v[:state] == 'deleted' }
          # it cancels all available volumes.
          rpc.request("hva-collector", 'finalize_instance', @inst[:uuid], Time.now.utc)
        else
          # do nothing and wait other volumes become available.
          @hva_ctx.logger.info("Waiting for volumes are ready.")
        end
      end

      job :wait_volumes_available, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)

        wait_volumes_available
      }

      job :run_local_store, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]

        @hva_ctx.logger.info("Booting instance")
        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless %w(initializing).member?(@inst[:state].to_s)
        if !@inst[:volume].values.all? {|v| v[:state] == 'available' }
          @hva_ctx.logger.error("Could not boot the instance. some volumes are not available yet: #{@inst[:volume].map{|volid, v| volid + ": " + v[:state] }.join(', ')}")
          return
        end

        setup_metadata_drive

        check_interface

        @inst[:volume].keys.each { |vol_uuid|
          update_volume_state(vol_uuid, {:state=>:attaching}, 'hva/volume_attached')
        }

        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :run_instance, [@hva_ctx])

        # Node specific instance_started event for netfilter and general instance_started event for openflow
        update_instance_state({:state=>:running}, ['hva/instance_started'])

        @inst[:volume].values.each { |v|
          update_volume_state(v[:uuid], {:state=>:attached, :attached_at=>Time.now.utc}, 'hva/volume_attached')
        }

        # Security group vnic joined events for vnet netfilter
        @inst[:vif].each { |vnic|
          event.publish("#{@inst[:host_node][:node_id]}/vnic_created", :args=>[vnic[:uuid]])
          vnic[:security_groups].each { |secg|
            event.publish("#{secg}/vnic_joined", :args=>[vnic[:uuid]])
          }
        }
      }, proc {
        ignore_error { terminate_instance(false) }
        ignore_error { finalize_instance() }
      }

      job :run_vol_store, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @vol_id = request.args[1]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        @hva_ctx.logger.info("Booting #{@inst_id}")
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        update_instance_state({:state=>:starting})

        # setup vm data folder
        inst_data_dir = @hva_ctx.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)

        # reload volume info
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        @hva_ctx.logger.info("Attaching #{@vol_id} on #{@inst_id}")
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        # attach disk
        attach_volume_to_host

        setup_metadata_drive

        # run vm
        check_interface
        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :run_instance, [@hva_ctx])
        # Node specific instance_started event for netfilter and general instance_started event for openflow
        update_instance_state({:state=>:running}, ['hva/instance_started'])

        update_volume_state(@vol_id, {:state=>:attached, :attached_at=>Time.now.utc}, 'hva/volume_attached')

        # Security group vnic joined events for vnet netfilter
        create_instance_vnics(@inst)
      }, proc {
        # TODO: Run detach & destroy volume
        ignore_error { terminate_instance(false) }
        ignore_error { finalize_instance() }
      }

      job :terminate do
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        unless ['running', 'halted'].member?(@inst[:state].to_s)
          raise "Invalid instance state: #{@inst[:state]}"
        end

        begin
          update_instance_state({:state=>:shuttingdown})
          ignore_error { terminate_instance(true) }
        ensure
          finalize_instance()
        end
      end

      # just do terminate instance and unmount volumes. it should not change
      # state on any resources.
      # called from HA at which the faluty instance get cleaned properly.
      job :cleanup do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        begin
          ignore_error { terminate_instance(false) }
        ensure
          # just publish "hva/instance_terminated" to update security group rules once
          finalize_instance
        end
      end

      # stop instance is mostly similar to terminate_instance. the
      # difference is the state transition of instance and associated
      # resources to the instance , attached volumes and vnic, are kept
      # same sate.
      job :stop do
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        begin
          update_instance_state({:state=>:stopping})
          ignore_error { terminate_instance(false) }
        ensure
          #
          update_instance_state_to_terminated({:state=>:stopped, :host_node_id=>nil})
        end
      end

      job :attach, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        @hva_ctx.logger.info("Attaching #{@vol_id}")
        raise "Invalid volume state: #{@vol[:state]}" unless @vol[:state].to_s == 'available'

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        # attach disk on host os
        attach_volume_to_host

        @hva_ctx.logger.info("Attaching #{@vol_id} on #{@inst_id}")

        # attach disk on guest os
        pci_devaddr=nil
        tryagain do
          pci_devaddr = task_session.invoke(@hva_ctx.hypervisor_driver_class,
                                            :attach_volume_to_guest, [@hva_ctx])
        end
        raise "Can't attach #{@vol_id} on #{@inst_id}" if pci_devaddr.nil?

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attached,
                      :attached_at=>Time.now.utc,
                      :guest_device_name=>pci_devaddr})
        event.publish('hva/volume_attached', :args=>[@inst_id, @vol_id])
        @hva_ctx.logger.info("Attached #{@vol_id} on #{@inst_id}")
      }, proc {
        # TODO: Run detach volume
        # push back volume state to available.
        ignore_error { update_volume_state(@vol_id, {:state=>:available},'hva/volume_available') }
        @hva_ctx.logger.error("Attach failed: #{@vol_id} on #{@inst_id}")
      }

      job :detach do
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        @hva_ctx.logger.info("Detaching #{@vol_id} on #{@inst_id}")
        raise "Invalid volume state: #{@vol[:state]}" unless @vol[:state].to_s == 'attached'

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:detaching, :detached_at=>nil})
        # detach disk on guest os
        tryagain do
          task_session.invoke(@hva_ctx.hypervisor_driver_class,
                              :detach_volume_from_guest, [@hva_ctx])
        end

        # detach disk on host os
        ignore_error { detach_volume_from_host }
        update_volume_state_to_available
      end

      def bridge_if(dc_network_name)
        dcn = Dcmgr.conf.dc_networks[dc_network_name]
        raise "Unknown DC network: #{dc_network_name}" if dcn.nil?
        dcn.bridge
      end

      job :attach_nic do
        @dc_network_name = request.args[0]
        @nic_id = request.args[1]
        @port_id = request.args[2]

        @bridge = bridge_if(@dc_network_name)
        logger.info("Attaching #{@nic_id} to #{@port_id} on #{@bridge}.")
        attach_vnic_to_port
      end

      job :detach_nic do
        @dc_network_name = request.args[0]
        @nic_id = request.args[1]
        @port_id = request.args[2]

        @bridge = bridge_if(@dc_network_name)
        logger.info("Detaching #{@nic_id} from #{@port_id} on #{@bridge}.")
        detach_vnic_from_port
      end

      job :reboot, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        @hva_ctx.logger.info("Rebooting")
        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :reboot_instance, [@hva_ctx])
        @hva_ctx.logger.info("Rebooted")
      }

      job :poweroff, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        update_state_file(:halting)

        @hva_ctx.logger.info("Turning power off")
        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :poweroff_instance, [@hva_ctx])
        update_instance_state({:state=>:halted}, [])
        destroy_instance_vnics(@inst)
        @hva_ctx.logger.info("Turned power off")
      }

      job :soft_poweroff, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        update_state_file(:halting)

        @hva_ctx.logger.info("Turning soft power off")
         task_session.invoke(@hva_ctx.hypervisor_driver_class,
                             :soft_poweroff_instance, [@hva_ctx])
        destroy_instance_vnics(@inst)
        @hva_ctx.logger.info("Turned soft power off")
      }

      job :poweron, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        update_instance_state({:state=>:starting}, [])

        setup_metadata_drive

        @hva_ctx.logger.info("Turning power on")
        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :poweron_instance, [@hva_ctx])
        update_instance_state({:state=>:running}, [])
        create_instance_vnics(@inst)
        @hva_ctx.logger.info("Turned power on")
      }, proc {
        ignore_error {
          update_instance_state({:state=>:halted}, [])
        }
      }

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end
  end
end
