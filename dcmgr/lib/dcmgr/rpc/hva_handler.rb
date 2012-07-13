# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'
require 'ipaddress'

module Dcmgr
  module Rpc
    class HvaHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper

      def select_hypervisor
        @hv = Dcmgr::Drivers::Hypervisor.select_hypervisor(@inst[:hypervisor])
      end

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

      def detach_volume_from_host
        # iscsi logout
        sh("iscsiadm -m node -T '%s' --logout", [@vol[:transport_information][:iqn]])
        # wait udev queue
        sh("/sbin/udevadm settle")
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

      # This method can be called sometime when the instance variables
      # are also failed to be set. They need to be checked before looked
      # up.
      def terminate_instance(state_update=false)
        if @hv && @hva_ctx
          @hv.terminate_instance(@hva_ctx)
        end

        if @inst && !@inst[:volume].nil?
          @inst[:volume].each { |volid, v|
            @vol_id = volid
            @vol = v
            # force to continue detaching volumes during termination.
            ignore_error { detach_volume_from_host }
            if state_update
              update_volume_state_to_available rescue @hva_ctx.logger.error($!)
            end
          }
        end
        
        # cleanup vm data folder
        FileUtils.rm_r(File.expand_path("#{@inst_id}", Dcmgr.conf.vm_data_dir)) unless @hv.is_a?(Dcmgr::Drivers::ESXi)
      end

      def update_instance_state(opts, ev)
        raise "Can't update instance info without setting @inst_id" if @inst_id.nil?
        rpc.request('hva-collector', 'update_instance', @inst_id, opts) do |req|
          req.oneshot = true
        end
        ev = [ev] unless ev.is_a? Array
        ev.each { |e|
          event.publish(e, :args=>[@inst_id])
        }
      end
      
      def update_instance_state_to_terminated(opts)
        update_instance_state(opts,
                                ['hva/instance_terminated',"#{@inst[:host_node][:node_id]}/instance_terminated"])

        # Security group vnic left events for vnet netfilter
        @inst[:vif].each { |vnic|
          event.publish("#{@inst[:host_node][:node_id]}/vnic_destroyed", :args=>[vnic[:uuid]])
          vnic[:security_groups].each { |secg|
            event.publish("#{secg}/vnic_left", :args=>[vnic[:uuid]])
          }
        }
      end

      def update_volume_state(opts, ev)
        raise "Can't update volume info without setting @vol_id" if @vol_id.nil?
        rpc.request('sta-collector', 'update_volume', @vol_id, opts) do |req|
          req.oneshot = true
        end
        event.publish(ev, :args=>[@vol_id])
      end

      def check_interface
        @hv.check_interface(@hva_ctx)
      end

      def attach_vnic_to_port
        sh("/sbin/ip link set %s up", [@nic_id])
        sh("/usr/sbin/brctl addif %s %s", [@bridge, @nic_id])
      end

      def detach_vnic_from_port
        sh("/sbin/ip link set %s down", [@nic_id])
        sh("/usr/sbin/brctl delif %s %s", [@bridge, @nic_id])
      end

      def get_linux_dev_path
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        @os_devpath = "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{@vol[:storage_node][:ipaddr]}:3260",
                                                                      @vol[:transport_information][:iqn],
                                                                      @vol[:transport_information][:lun]]
      end

      def setup_metadata_drive
        @hv.setup_metadata_drive(@hva_ctx,get_metadata_items)
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
          'instance-type' => @inst[:request_params][:instance_spec_id],
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
            "network/interfaces/macs/#{mac}/x-netmask" => netaddr.prefix.to_ip,
            "network/interfaces/macs/#{mac}/x-network" => vnic[:ipv4][:network][:ipv4_network],
            "network/interfaces/macs/#{mac}/x-broadcast" => netaddr.broadcast,
            "network/interfaces/macs/#{mac}/x-metric" => vnic[:ipv4][:network][:metric],
          })
        }

        if @inst[:ssh_key_data]
          metadata_items.merge!({
            "public-keys/0=#{@inst[:ssh_key_data][:name]}" => @inst[:ssh_key_data][:public_key],
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
          @hva_ctx.logger.error("Ignoring error: #{e.message}")
          @hva_ctx.logger.error(e)
        end
      end

      job :run_local_store, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @hva_ctx.logger.info("Booting #{@inst_id}")

        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc, :esxi
        select_hypervisor

        @os_devpath = File.expand_path("#{@hva_ctx.inst[:uuid]}", @hva_ctx.inst_data_dir)

        lstore = Drivers::LocalStore.select_local_store(@hv.class.to_s.downcase.split('::').last)
        lstore.deploy_image(@inst,@hva_ctx)

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})

        sleep 1

        #setup_metadata_drive
        @hv.setup_metadata_drive(@hva_ctx,get_metadata_items)
        
        check_interface
        @hv.run_instance(@hva_ctx)
        # Node specific instance_started event for netfilter and general instance_started event for openflow
        update_instance_state({:state=>:running}, ['hva/instance_started'])
        
        # Security group vnic joined events for vnet netfilter
        @inst[:vif].each { |vnic|
          event.publish("#{@inst[:host_node][:node_id]}/vnic_created", :args=>[vnic[:uuid]])
          vnic[:security_groups].each { |secg|
            event.publish("#{secg}/vnic_joined", :args=>[vnic[:uuid]])
          }
        }
      }, proc {
        ignore_error { terminate_instance(false) }
        ignore_error {
          update_instance_state_to_terminated({:state=>:terminated, :terminated_at=>Time.now.utc})
        }
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

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})

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
        @hv.run_instance(@hva_ctx)
        # Node specific instance_started event for netfilter and general instance_started event for openflow
        update_instance_state({:state=>:running}, ['hva/instance_started'])
        
        update_volume_state({:state=>:attached, :attached_at=>Time.now.utc}, 'hva/volume_attached')
        
        # Security group vnic joined events for vnet netfilter
        @inst[:vif].each { |vnic|
          event.publish("#{@inst[:host_node][:node_id]}/vnic_created", :args=>[vnic[:uuid]])
          
          vnic[:security_groups].each { |secg|
            event.publish("#{secg}/vnic_joined", :args=>[vnic[:uuid]])
          }
        }
      }, proc {
        # TODO: Run detach & destroy volume
        ignore_error { terminate_instance(false) }
        ignore_error {
          update_instance_state_to_terminated({:state=>:terminated, :terminated_at=>Time.now.utc})
        }
        ignore_error {
          update_volume_state({:state=>:deleted, :deleted_at=>Time.now.utc},
                              'hva/volume_deleted')
        }
      }

      job :terminate do
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        begin
          rpc.request('hva-collector', 'update_instance',  @inst_id, {:state=>:shuttingdown})
          ignore_error { terminate_instance(true) }
        ensure
          update_instance_state_to_terminated({:state=>:terminated,:terminated_at=>Time.now.utc})
        end
      end

      # just do terminate instance and unmount volumes. it should not change
      # state on any resources.
      # called from HA at which the faluty instance get cleaned properly.
      job :cleanup do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        begin
          ignore_error { terminate_instance(false) }
        ensure
          # just publish "hva/instance_terminated" to update security group rules once
          update_instance_state_to_terminated({})
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

        select_hypervisor

        begin
          rpc.request('hva-collector', 'update_instance',  @inst_id, {:state=>:stopping})
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

        # select hypervisor :kvm, :lxc
        select_hypervisor

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
          pci_devaddr = @hv.attach_volume_to_guest(@hva_ctx)
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
        ignore_error { update_volume_state({:state=>:available},'hva/volume_available') }
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

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:detaching, :detached_at=>nil})
        # detach disk on guest os
        tryagain do
          @hv.detach_volume_from_guest(@hva_ctx)
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

        # select_hypervisor :kvm, :lxc
        select_hypervisor

        # reboot instance
        @hv.reboot_instance(@hva_ctx)
      }

      job :backup_image, proc {
        @inst_id = request.args[0]
        @backupobject_id = request.args[1]
        @image_id = request.args[2]
        @hva_ctx = HvaContext.new(self)

        @hva_ctx.logger.info("Backing up the image file for #{@inst_id} as #{@backupobject_id}.")
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @bo = rpc.request('sta-collector', 'get_backup_object', @backupobject_id)
        @os_devpath = File.expand_path("#{@hva_ctx.inst[:uuid]}", @hva_ctx.inst_data_dir)

        raise "Invalid instance state (expected running): #{@inst[:state]}" if @inst[:state].to_s != 'running'
        #raise "Invalid volume state: #{@volume[:state]}" unless %w(available attached).member?(@volume[:state].to_s)

        begin
          snap_filename = @hva_ctx.os_devpath

          ev_callback = proc { |cmd, *value|
            case cmd
            when :setattr
              # update checksum & allocation_size of the backup object
              rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {
                            :checksum=>value[0],
                            :allocation_size => value[1],
                          })
            when :progress
              # update upload progress of backup object
              #rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:progress=>value[0]}) do |req|
              #  req.oneshot = true
              #end
            else
              raise "Unknown callback command: #{cmd}"
            end
          }.tap { |i|
            i.instance_eval {
              def setattr(checksum, alloc_size)
                self.call(:setattr, checksum, alloc_size)
              end

              def progress(percent)
                self.call(:progress, percent)
              end
            }
          }

          @hva_ctx.logger.info("Uploading #{snap_filename} (#{@backupobject_id})")
          lstore = Drivers::LocalStore.select_local_store(@inst[:host_node][:hypervisor])
          lstore.upload_image(@inst, @hva_ctx, @bo, ev_callback)
          
          @hva_ctx.logger.info("Uploaded #{snap_filename} (#{@backupobject_id}) successfully")
      
        rescue => e
          @hva_ctx.logger.error(e)
          raise "snapshot has not be uploaded"
        end
        
        rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:state=>:available})
        rpc.request('hva-collector', 'update_image', @image_id, {:state=>:available})
        @hva_ctx.logger.info("uploaded new backup object: #{@inst_id} #{@backupobject_id} #{@image_id}")
        
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        rpc.request('hva-collector', 'update_image', @image_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        @hva_ctx.logger.error("Failed to run backup_image: #{@inst_id} #{@backupobject_id} #{@image_id}")
      }

      job :poweroff, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        select_hypervisor

        @hv.poweroff_instance(@hva_ctx)
        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:halted})
        logger.info("PowerOff #{@inst_id}")
      }

      job :poweron, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        select_hypervisor

        # reboot instance
        @hv.poweron_instance(@hva_ctx)
        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:running})
        logger.info("PowerOn #{@inst_id}")
      }
      
      def rpc
        @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
      end

      def jobreq
        @jobreq ||= Isono::NodeModules::JobChannel.new(@node)
      end

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end

    class HvaContext

      def initialize(hvahandler)
        raise "Invalid Class: #{hvahandler}" unless hvahandler.instance_of?(HvaHandler)
        @hva = hvahandler
      end

      def node
        @hva.instance_variable_get(:@node)
      end

      def inst_id
        @hva.instance_variable_get(:@inst_id)
      end

      def inst
        @hva.instance_variable_get(:@inst)
      end

      def os_devpath
        @hva.instance_variable_get(:@os_devpath)
      end

      def metadata_img_path
        File.expand_path('metadata.img', inst_data_dir)
      end

      def vol
        @hva.instance_variable_get(:@vol)
      end

      def rpc
        @hva.rpc
      end

      def inst_data_dir
        File.expand_path("#{inst_id}", Dcmgr.conf.vm_data_dir)
      end

      def logger
        CustomLogger.new(self)
      end

      class CustomLogger
        def initialize(hva_context)
          @hva_context = hva_context
        end

        ["fatal", "error", "warn", "info", "debug"].each do |level|
          define_method(level){|msg|
            logger.__send__(level, "#{msg} (inst_id: #{@hva_context.inst_id})")
          }
        end

        def default_logdev
          ::Logger::LogDevice.new($>)
        end

        def logger
          l = ::Logger.new(default_logdev)
          l.progname = "HvaHandler"
          l
        end


      end

    end

  end
end
