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
        @hv = Dcmgr::Drivers::Hypervisor.select_hypervisor(@inst[:instance_spec][:hypervisor])
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
              update_volume_state_to_available rescue logger.error($!)
            end
          }
        end
        
        # cleanup vm data folder
        FileUtils.rm_r(File.expand_path("#{@inst_id}", @node.manifest.config.vm_data_dir)) unless @hv.is_a?(Dcmgr::Drivers::ESXi)
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
        @inst[:security_groups].each { |secg|
          @inst[:vif].each { |vnic|
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
        sh("/usr/sbin/brctl addif %s %s", [@link_interface, @nic_id])
      end

      def detach_vnic_from_port
        sh("/sbin/ip link set %s down", [@nic_id])
        sh("/usr/sbin/brctl delif %s %s", [@link_interface, @nic_id])
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
        vnic = @inst[:instance_nics].first || {}
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
          'instance-type' => @inst[:instance_spec][:uuid],
          'kernel-id' => nil,
          'local-hostname' => @inst[:hostname],
          'local-ipv4' => @inst[:ips].first,
          'mac' => vnic[:mac_addr].unpack('A2'*6).join(':'),
          'placement/availability-zone' => nil,
          'product-codes' => nil,
          'public-hostname' => @inst[:hostname],
          'public-ipv4'    => @inst[:nat_ips].first,
          'ramdisk-id' => nil,
          'reservation-id' => nil,
          'security-groups' => @inst[:security_groups].join(' '),
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
            "network/interfaces/macs/#{mac}/security-groups" => @inst[:security_groups].join(' '),
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
          logger.error("Ignoring error: #{e.message}")
          logger.error(e)
        end
      end

      job :run_local_store, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        logger.info("Booting #{@inst_id}")

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
        update_instance_state({:state=>:running}, ['hva/instance_started',"#{@inst[:host_node][:node_id]}/instance_started"])
        
        # Security group vnic joined events for vnet netfilter
        @inst[:security_groups].each { |secg|
          @inst[:vif].each { |vnic|
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
        logger.info("Booting #{@inst_id}")
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
        logger.info("Attaching #{@vol_id} on #{@inst_id}")
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
        update_instance_state({:state=>:running}, ['hva/instance_started',"#{@inst[:host_node][:node_id]}/instance_started"])
        update_volume_state({:state=>:attached, :attached_at=>Time.now.utc}, 'hva/volume_attached')
        
        # Security group vnic joined events for vnet netfilter
        @inst[:security_groups].each { |secg|
          @inst[:vif].each { |vnic|
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
        logger.info("Attaching #{@vol_id}")
        raise "Invalid volume state: #{@vol[:state]}" unless @vol[:state].to_s == 'available'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        # attach disk on host os
        attach_volume_to_host

        logger.info("Attaching #{@vol_id} on #{@inst_id}")

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
        logger.info("Attached #{@vol_id} on #{@inst_id}")
      }, proc {
        # TODO: Run detach volume
        # push back volume state to available.
        ignore_error { update_volume_state({:state=>:available},'hva/volume_available') }
        logger.error("Attach failed: #{@vol_id} on #{@inst_id}")
      }

      job :detach do
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Detaching #{@vol_id} on #{@inst_id}")
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

      job :attach_nic do
        @link_interface = request.args[0]
        @nic_id = request.args[1]
        @port_id = request.args[2]

        if @link_interface
          logger.info("Attaching #{@nic_id} to #{@port_id} on #{@link_interface}.")
          attach_vnic_to_port
        else
          logger.info("Attaching #{@nic_id} to #{@port_id} failed: no network / link interface found.")
        end
      end

      job :detach_nic do
        @link_interface = request.args[0]
        @nic_id = request.args[1]
        @port_id = request.args[2]

        if @link_interface
          logger.info("Detaching #{@nic_id} from #{@port_id} on #{@link_interface}.")
          detach_vnic_from_port
        else
          logger.info("Detaching #{@nic_id} from #{@port_id} failed: no network / link interface found.")
        end
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
        File.expand_path("#{inst_id}", node.manifest.config.vm_data_dir)
      end
    end

  end
end
