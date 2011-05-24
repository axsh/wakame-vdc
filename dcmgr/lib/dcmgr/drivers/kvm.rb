module Dcmgr
  module Drivers
    class Kvm
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Rpc::KvmHelper
      include Dcmgr::Helpers::NicHelper

      def run_instance(inst, data)
        # run vm
        cmd = "kvm -m %d -smp %d -name vdc-%s -vnc :%d -drive file=%s -pidfile %s -daemonize -monitor telnet::%d,server,nowait"
        args=[inst[:instance_spec][:memory_size],
              inst[:instance_spec][:cpu_cores],
              inst[:uuid],
              inst[:runtime_config][:vnc_port],
              data[:os_devpath],
              File.expand_path('kvm.pid', data[:inst_data_dir]),
              inst[:runtime_config][:telnet_port]
             ]
        if vnic = inst[:instance_nics].first
          cmd += " -net nic,macaddr=%s -net tap,ifname=%s,script=,downscript="
          args << vnic[:mac_addr].unpack('A2'*6).join(':')
          args << vnic[:uuid]
        end
        sh(cmd, args)

        unless vnic.nil?
          node = data[:node]
          network_map = data[:network_map]

          # physical interface
          physical_if = find_nic(node.manifest.config.hv_ifindex)
          raise "UnknownPhysicalNIC" if physical_if.nil?

          if network_map[:vlan_id] == 0
            # bridge interface
            bridge_if = node.manifest.config.bridge_novlan
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
            bridge_if = "#{node.manifest.config.bridge_prefix}-#{physical_if}.#{network_map[:vlan_id]}"
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

      def terminate_instance(inst_id)
        kvm_pid=`pgrep -u root -f vdc-#{inst_id}`
        if $?.exitstatus == 0 && kvm_pid.to_s =~ /^\d+$/
          sh("/bin/kill #{kvm_pid}")
        else
          logger.error("Can not find the KVM process. Skipping: kvm -name vdc-#{inst_id}")
        end
      end

      def reboot_instance(inst)
        connect_monitor(inst[:runtime_config][:telnet_port]) { |t|
          t.cmd("system_reset")
        }
      end

      def attach_volume_to_guest(inst, data)
        # pci_devddr consists of three hex numbers with colon separator.
        #  dom <= 0xffff && bus <= 0xff && val <= 0x1f
        # see: qemu-0.12.5/hw/pci.c
        # /*
        # * Parse [[<domain>:]<bus>:]<slot>, return -1 on error
        # */
        # static int pci_parse_devaddr(const char *addr, int *domp, int *busp, unsigned *slotp)
        pci_devaddr = nil

        sddev = File.expand_path(File.readlink(data[:linux_dev_path]), '/dev/disk/by-path')
        connect_monitor(inst[:runtime_config][:telnet_port]) { |t|
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
        pci_devaddr.join(':')
      end

      def detach_volume_from_guest(guest_device_name, data)
        pci_devaddr = guest_device_name

        connect_monitor(data[:telnet_port]) { |t|
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
      end

    end
  end
end
