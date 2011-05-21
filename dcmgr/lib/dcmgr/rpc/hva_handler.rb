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

      def run_kvm(os_devpath)
        # run vm
        cmd = "kvm -m %d -smp %d -name vdc-%s -vnc :%d -drive file=%s -pidfile %s -daemonize -monitor telnet::%d,server,nowait"
        args=[@inst[:instance_spec][:memory_size],
              @inst[:instance_spec][:cpu_cores],
              @inst_id,
              @inst[:runtime_config][:vnc_port],
              os_devpath,
              File.expand_path('kvm.pid', @inst_data_dir),
              @inst[:runtime_config][:telnet_port]
             ]
        if vnic = @inst[:instance_nics].first
          cmd += " -net nic,macaddr=%s -net tap,ifname=%s,script=,downscript="
          args << vnic[:mac_addr].unpack('A2'*6).join(':')
          args << vnic[:uuid]
        end
        sh(cmd, args)

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
            if valid_nic?(vlan_if)
              sh("/sbin/vconfig add #{physical_if} #{network_map[:vlan_id]}")
            end

            # bridge interface
            bridge_if = "#{@node.manifest.config.bridge_prefix}-#{physical_if}.#{network_map[:vlan_id]}"
            if valid_nic?(bridge_if)
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

          sh("/sbin/ifconfig %s 0.0.0.0 up", [vnic[:uuid]])
          sh("/usr/sbin/brctl addif %s %s", [bridge_if, vnic[:uuid]])
        end

        sleep 1
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
        kvm_pid=`pgrep -u root -f vdc-#{@inst_id}`
        if $?.exitstatus == 0 && kvm_pid.to_s =~ /^\d+$/
          sh("/bin/kill #{kvm_pid}")
        else
          logger.error("Can not find the KVM process. Skipping: kvm -name vdc-#{@inst_id}")
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

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})
        # setup vm data folder
        @inst_data_dir = File.expand_path("#{@inst_id}", @node.manifest.config.vm_data_dir)
        FileUtils.mkdir(@inst_data_dir) unless File.exists?(@inst_data_dir)
        # copy image file
        img_src = @inst[:image][:source]
        case img_src[:type].to_sym
        when :http
          img_path = File.expand_path("#{@inst[:uuid]}", @inst_data_dir)
          sh("curl --silent -o '#{img_path}' #{img_src[:uri]}")
          sleep 1
        else
          raise "Unknown image source type: #{img_src[:type]}"
        end

        run_kvm(img_path)
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
        run_kvm(linux_dev_path)
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

        # pci_devddr consists of three hex numbers with colon separator.
        #  dom <= 0xffff && bus <= 0xff && val <= 0x1f
        # see: qemu-0.12.5/hw/pci.c
        # /*
        # * Parse [[<domain>:]<bus>:]<slot>, return -1 on error
        # */
        # static int pci_parse_devaddr(const char *addr, int *domp, int *busp, unsigned *slotp)
        pci_devaddr = nil

        sddev = File.expand_path(File.readlink(linux_dev_path), '/dev/disk/by-path')
        connect_monitor(@inst[:runtime_config][:telnet_port]) { |t|
          # success message:
          #   OK domain 0, bus 0, slot 4, function 0
          # error message:
          #   failed to add file=/dev/xxxx,if=virtio
          c = t.cmd("pci_add auto storage file=#{sddev},if=scsi")
          # Note: pci_parse_devaddr() called in "pci_add" uses strtoul()
          # with base 16 so that the input is expected in hex. however
          # at the result display, void pci_device_hot_add_print() uses
          # %d for showing bus and slot addresses. use hex to preserve
          # those values to keep consistent.
          if c =~ /\nOK domain ([0-9a-fA-F]+), bus ([0-9a-fA-F]+), slot ([0-9a-fA-F]+), function/m
            # numbers in OK result is decimal. convert them to hex.
            pci_devaddr = [$1, $2, $3].map{|i| i.to_i.to_s(16) }
          else
            raise "Error in qemu console: #{c}"
          end

          # double check the pci address.
          c = t.cmd("info pci")

          # static void pci_info_device(PCIBus *bus, PCIDevice *d)
          # called in "info pci" gets back PCI bus info with %d.
          if c.split(/\n/).grep(/^\s+Bus\s+#{pci_devaddr[1].to_i(16)}, device\s+#{pci_devaddr[2].to_i(16)}, function/).empty?
            raise "Could not find new disk device attached to qemu-kvm: #{pci_devaddr.join(':')}"
          end
        }

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attached,
                      :attached_at=>Time.now.utc,
                      :guest_device_name=>pci_devaddr.join(':')})
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

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:detaching, :detached_at=>nil})
        # detach disk on guest os
        pci_devaddr = @vol[:guest_device_name]

        connect_monitor(@inst[:runtime_config][:telnet_port]) { |t|
          t.cmd("pci_del #{pci_devaddr}")
          #
          #  Bus  0, device   4, function 0:
          #    SCSI controller: PCI device 1af4:1001
          #      IRQ 0.
          #      BAR0: I/O at 0x1000 [0x103f].
          #      BAR1: 32 bit memory at 0x08000000 [0x08000fff].
          #      id ""
          c = t.cmd("info pci")
          pci_devaddr = pci_devaddr.split(':')
          unless c.split(/\n/).grep(/\s+Bus\s+#{pci_devaddr[1].to_i(16)}, device\s+#{pci_devaddr[2].to_i(16)}, function/).empty?
            raise "Detached disk device still be attached in qemu-kvm: #{pci_devaddr.join(':')}"
          end
        }

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
