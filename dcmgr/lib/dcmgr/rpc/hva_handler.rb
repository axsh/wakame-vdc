# -*- coding: utf-8 -*-
require 'isono'
require 'net/telnet'
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
        hypervisor = @inst[:instance_spec][:hypervisor]
        case hypervisor
        when "kvm"
          @hv = Dcmgr::Drivers::Kvm.new
        when "lxc"
          @hv = Dcmgr::Drivers::Lxc.new
        else
          raise "Unknown hypervisor type: #{hypervisor}"
        end
      end

      def attach_volume_to_host
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        linux_dev_path = "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{@vol[:storage_pool][:ipaddr]}:3260",
                                                                      @vol[:transport_information][:iqn],
                                                                      @vol[:transport_information][:lun]]

        tryagain do
          next true if File.exist?(linux_dev_path)

          sh("iscsiadm -m discovery -t sendtargets -p %s", [@vol[:storage_pool][:ipaddr]])
          sh("iscsiadm -m node -l -T '%s' --portal '%s'",
             [@vol[:transport_information][:iqn], @vol[:storage_pool][:ipaddr]])
          sleep 1
        end

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attaching,
                      :attached_at => nil,
                      :host_device_name => linux_dev_path})
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
        hypervisor = @inst[:instance_spec][:hypervisor]
        case hypervisor
        when "kvm"
          @hv.terminate_instance(@inst_id)
        when "lxc"
          inst_data_dir = File.expand_path("#{@inst_id}", @node.manifest.config.vm_data_dir)
          @hv.terminate_instance(@inst_id, inst_data_dir)
        else
          raise "Unknown hypervisor type: #{hypervisor}"
        end
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

      job :run_local_store, proc {
        @inst_id = request.args[0]
        logger.info("Booting #{@inst_id}")

        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless %w(init failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})
        # setup vm data folder
        @inst_data_dir = File.expand_path("#{@inst_id}", @node.manifest.config.vm_data_dir)
        FileUtils.mkdir(@inst_data_dir) unless File.exists?(@inst_data_dir)
        # copy image file
        img_src = @inst[:image][:source]
        img_path = File.expand_path("#{@inst[:uuid]}", @inst_data_dir)
        sh("curl --silent -o '#{img_path}' #{img_src[:uri]}")
        sleep 1

        vnic = @inst[:instance_nics].first
        network_map = nil
        unless vnic.nil?
          network_map = rpc.request('hva-collector', 'get_network', @inst[:instance_nics].first[:network_id])
        end

        @hv.run_instance(@inst, {:node=>@node,
                           :inst_data_dir=>@inst_data_dir,
                           :os_devpath=>img_path,
                           :network_map=>network_map})
        update_instance_state({:state=>:running}, 'hva/instance_started')
      }, proc {
        update_instance_state({:state=>:terminated, :terminated_at=>Time.now.utc},
                              'hva/instance_terminated')
      }

      job :run_vol_store, proc {
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Booting #{@inst_id}")
        raise "Invalid instance state: #{@inst[:state]}" unless %w(init failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})

        # setup vm data folder
        @inst_data_dir = File.expand_path("#{@inst_id}", @node.manifest.config.vm_data_dir)
        FileUtils.mkdir(@inst_data_dir) unless File.exists?(@inst_data_dir)

        # create volume from snapshot
        jobreq.run("zfs-handle.#{@vol[:storage_pool][:node_id]}", "create_volume", @vol_id)

        logger.debug("volume created on #{@vol[:storage_pool][:node_id]}: #{@vol_id}")
        # reload volume info
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        
        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        logger.info("Attaching #{@vol_id} on #{@inst_id}")
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        linux_dev_path = "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{@vol[:storage_pool][:ipaddr]}:3260",
                                                                      @vol[:transport_information][:iqn],
                                                                      @vol[:transport_information][:lun]]

        # attach disk
        attach_volume_to_host
        
        # run vm
        vnic = @inst[:instance_nics].first
        network_map = nil
        unless vnic.nil?
          network_map = rpc.request('hva-collector', 'get_network', @inst[:instance_nics].first[:network_id])
        end

        @hv.run_instance(@inst, {:node=>@node,
                         :inst_data_dir=>@inst_data_dir,
                         :os_devpath=>linux_dev_path,
                         :network_map=>network_map})
        update_instance_state({:state=>:running}, 'hva/instance_started')
        update_volume_state({:state=>:attached, :attached_at=>Time.now.utc}, 'hva/volume_attached')
      }, proc {
        update_instance_state({:state=>:terminated, :terminated_at=>Time.now.utc},
                              'hva/instance_terminated')
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
        linux_dev_path = "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{@vol[:storage_pool][:ipaddr]}:3260",
                                                                      @vol[:transport_information][:iqn],
                                                                      @vol[:transport_information][:lun]]

        # attach disk on host os
        attach_volume_to_host

        logger.info("Attaching #{@vol_id} on #{@inst_id}")

        # attach disk on guest os
        pci_devaddr = @hv.attach_volume_to_guest(@inst, linux_dev_path)

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
        @hv.detach_volume_from_guest(@vol, @inst)

        # detach disk on host os
        detach_volume_from_host
      end

      job :reboot, proc {
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        
        connect_monitor(@inst[:runtime_config][:telnet_port]) { |t|
          t.cmd("system_reset")
        }
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
  end
end
