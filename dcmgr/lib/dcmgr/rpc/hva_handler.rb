# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'

module Dcmgr
  module Rpc
    module KvmHelper
      # Establish telnet connection to KVM monitor console
      def connect_monitor(port, &blk)
        begin
          telnet = ::Net::Telnet.new("Host" => "localhost",
                                     "Port"=>port.to_s,
                                     "Prompt" => /\n\(qemu\) \z/,
                                     "Timeout" => 60,
                                     "Waittime" => 0.2)

          blk.call(telnet)
        rescue => e
          logger.error(e) if self.respond_to?(:logger)
          raise e
        ensure
          telnet.close
        end
      end
    end
    
    class HvaHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include KvmHelper
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
          sleep 1
        end

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attaching,
                      :attached_at => nil,
                      :host_device_name => @os_devpath})
      end

      def detach_volume_from_host
        # iscsi logout
        sh("iscsiadm -m node -T '%s' --logout", [@vol[:transport_information][:iqn]])
        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:available,
                      :host_device_name=>nil,
                      :instance_id=>nil,
                      :detached_at => Time.now.utc,
                    })
        event.publish('hva/volume_detached', :args=>[@inst_id, @vol_id])
      end

      def terminate_instance
        @hv.terminate_instance(HvaContext.new(self))
      end
      

      def update_instance_state(opts, ev)
        raise "Can't update instance info without setting @inst_id" if @inst_id.nil?
        rpc.request('hva-collector', 'update_instance', @inst_id, opts)
        event.publish(ev, :args=>[@inst_id])
      end

      def update_volume_state(opts, ev)
        raise "Can't update volume info without setting @vol_id" if @vol_id.nil?
        rpc.request('sta-collector', 'update_volume', @vol_id, opts)
        event.publish(ev, :args=>[@vol_id])
      end

      def check_interface
        vnic = @inst[:instance_nics].first
        unless vnic.nil?
          network_map = rpc.request('hva-collector', 'get_network', @inst[:instance_nics].first[:network_id])

          # physical interface
          physical_if = find_nic(@node.manifest.config.hv_ifindex)
          raise "UnknownPhysicalNIC" if physical_if.nil?

          if network_map[:vlan_id] == 0
            # bridge interface
            bridge_if = @node.manifest.config.bridge_novlan
            unless valid_nic?(bridge_if)
              sh("/usr/sbin/brctl addbr %s",    [bridge_if])
              sh("/usr/sbin/brctl addif %s %s", [bridge_if, physical_if])
            end
          else
            # vlan interface
            vlan_if = "#{physical_if}.#{network_map[:vlan_id]}"
            unless valid_nic?(vlan_if)
              sh("/sbin/vconfig add #{physical_if} #{network_map[:vlan_id]}")
            end

            # bridge interface
            bridge_if = "#{@node.manifest.config.bridge_prefix}-#{physical_if}.#{network_map[:vlan_id]}"
            unless valid_nic?(bridge_if)
              sh("/usr/sbin/brctl addbr %s",    [bridge_if])
              sh("/usr/sbin/brctl addif %s %s", [bridge_if, vlan_if])
            end
          end

          # interface up? down?
          [ vlan_if, bridge_if ].each do |ifname|
            if nic_state(ifname) == "down"
              sh("/sbin/ifconfig #{ifname} 0.0.0.0 up")
            end
          end
          sleep 1
          bridge_if
        end
      end


      def get_linux_dev_path
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        @os_devpath = "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{@vol[:storage_node][:ipaddr]}:3260",
                                                                      @vol[:transport_information][:iqn],
                                                                      @vol[:transport_information][:lun]]
      end

      job :run_local_store, proc {
        @inst_id = request.args[0]
        logger.info("Booting #{@inst_id}")

        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc
        select_hypervisor

        # create hva context
        hc = HvaContext.new(self)

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})
        # setup vm data folder
        inst_data_dir = hc.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)
        # copy image file
        img_src = @inst[:image][:source]
        @os_devpath = File.expand_path("#{@inst[:uuid]}", inst_data_dir)

        # vmimage cache
        vmimg_cache_dir = File.expand_path("_base", @node.manifest.config.vm_data_dir)
        FileUtils.mkdir_p(vmimg_cache_dir) unless File.exists?(vmimg_cache_dir)
        vmimg_basename = File.basename(img_src[:uri])
        vmimg_cache_path = File.expand_path(vmimg_basename, vmimg_cache_dir)

        logger.debug("preparing #{@os_devpath}")

        # vmimg cached?
        unless File.exists?(vmimg_cache_path)
          logger.debug("copying #{vmimg_cache_path} from #{img_src[:uri]}")
          sh("curl --silent -o '#{vmimg_cache_path}' #{img_src[:uri]}")
        else
          md5sum = sh("md5sum #{vmimg_cache_path}")
          if md5sum[:stdout].split(' ')[0] == @inst[:image][:md5sum]
            logger.debug("verified vm cache image: #{vmimg_cache_path}")
          else
            logger.debug("not verified vm cache image: #{vmimg_cache_path}")
            sh("rm -f %s", [vmimg_cache_path])
            tmp_id = Isono::Util::gen_id
            logger.debug("copying #{vmimg_cache_path} from #{img_src[:uri]}")
            sh("curl --silent -o '#{vmimg_cache_path}.#{tmp_id}' #{img_src[:uri]}")
            sh("mv #{vmimg_cache_path}.#{tmp_id} #{vmimg_cache_path}")
            logger.debug("vmimage cache deployed on #{vmimg_cache_path}")
          end
        end

        ####
        logger.debug("copying #{@os_devpath} from #{vmimg_cache_path}")
        sh("cp -p --sparse=always %s %s",[vmimg_cache_path, @os_devpath])
        sleep 1

        @bridge_if = check_interface
        @hv.run_instance(hc)
        update_instance_state({:state=>:running}, 'hva/instance_started')
      }, proc {
        update_instance_state({:state=>:terminated, :terminated_at=>Time.now.utc},
                              'hva/instance_terminated')
      }

      job :run_vol_store, proc {
        @inst_id = request.args[0]
        @vol_id = request.args[1]
        @repository_address = request.args[2]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Booting #{@inst_id}")
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc
        select_hypervisor

        # create hva context
        hc = HvaContext.new(self)

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})

        # setup vm data folder
        inst_data_dir = hc.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)

        # create volume from snapshot
        jobreq.run("sta-handle.#{@vol[:storage_node][:node_id]}", "create_volume", @vol_id, @repository_address)

        logger.debug("volume created on #{@vol[:storage_node][:node_id]}: #{@vol_id}")
        # reload volume info
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        
        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        logger.info("Attaching #{@vol_id} on #{@inst_id}")
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        # attach disk
        attach_volume_to_host
        
        # run vm
        @bridge_if = check_interface
        @hv.run_instance(HvaContext.new(self))
        update_instance_state({:state=>:running}, 'hva/instance_started')
        update_volume_state({:state=>:attached, :attached_at=>Time.now.utc}, 'hva/volume_attached')
      }, proc {
        update_instance_state({:state=>:terminated, :terminated_at=>Time.now.utc},
                              'hva/instance_terminated')
        update_volume_state({:state=>:deleted, :deleted_at=>Time.now.utc},
                              'hva/volume_deleted')
      }

      job :terminate do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        begin
          rpc.request('hva-collector', 'update_instance',  @inst_id, {:state=>:shuttingdown})

          terminate_instance

          unless @inst[:volume].nil?
            @inst[:volume].each { |volid, v|
              @vol_id = volid
              @vol = v
              # force to continue detaching volumes during termination.
              detach_volume_from_host rescue logger.error($!)
            }
          end

          # cleanup vm data folder
          FileUtils.rm_r(File.expand_path("#{@inst_id}", @node.manifest.config.vm_data_dir))
        ensure
          update_instance_state({:state=>:terminated,:terminated_at=>Time.now.utc},
                                'hva/instance_terminated')
        end
      end

      # just do terminate instance and unmount volumes not to affect
      # state management.
      # called from HA at which the faluty instance get cleaned properly.
      job :cleanup do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        begin
          terminate_instance

          unless @inst[:volume].nil?
            @inst[:volume].each { |volid, v|
              @vol_id = volid
              @vol = v
              # force to continue detaching volumes during termination.
              detach_volume_from_host rescue logger.error($!)
            }
          end
        end

      end

      job :attach, proc {
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
        pci_devaddr = @hv.attach_volume_to_guest(HvaContext.new(self))

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attached,
                      :attached_at=>Time.now.utc,
                      :guest_device_name=>pci_devaddr})
        event.publish('hva/volume_attached', :args=>[@inst_id, @vol_id])
        logger.info("Attached #{@vol_id} on #{@inst_id}")
      }

      job :detach do
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
        @hv.detach_volume_from_guest(HvaContext.new(self))

        # detach disk on host os
        detach_volume_from_host
      end

      job :reboot, proc {
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        # select_hypervisor :kvm, :lxc
        select_hypervisor

        # check interface
        @bridge_if = check_interface

        # reboot instance
        @hv.reboot_instance(HvaContext.new(self))
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

      def bridge_if
        @hva.instance_variable_get(:@bridge_if)
      end

      def vol
        @hva.instance_variable_get(:@vol)
      end

      def inst_data_dir
        File.expand_path("#{inst_id}", node.manifest.config.vm_data_dir)
      end
    end

  end
end
