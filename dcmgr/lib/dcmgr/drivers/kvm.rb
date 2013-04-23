# -*- coding: utf-8 -*-

require 'net/telnet'

module Dcmgr
  module Drivers
    class Kvm < LinuxHypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper

      def_configuration do
        param :qemu_path, :default=>proc { ||
          if File.exists?('/etc/debian_version')
            '/usr/bin/kvm'
          else
            '/usr/libexec/qemu-kvm'
          end
        }

        param :qemu_options, :default=>'-no-kvm-pit-reinjection'
      end

      # 0x0-2 are reserved by KVM.
      # 0=Host bridge
      # 1=ISA bridge
      # 2=VGA
      KVM_NIC_PCI_ADDR_OFFSET=0x10
      
      def initialize
        @qemu_ver_str = `#{driver_configuration.qemu_path} -version`.chomp
        @qemu_version = if @qemu_ver_str =~ /^QEMU emulator version ([\d\.]+) \(/
                          $1
                        elsif @qemu_ver_str =~ /^QEMU PC emulator version ([\d\.]+) \(/
                          $1
                        else
                          raise "Failed to parse qemu version string: #{@qemu_ver_str}"
                        end
      end

      def run_instance(hc)
        poweron_instance(hc)
      end
      
      def poweron_instance(hc)

        # tcp listen ports for KVM monitor and VNC console
        monitor_tcp_port = pick_tcp_listen_port
        vnc_tcp_port = pick_tcp_listen_port
        serial_tcp_port = pick_tcp_listen_port
        hc.dump_instance_parameter('monitor.port', monitor_tcp_port)
        hc.dump_instance_parameter('vnc.port', vnc_tcp_port)
        hc.dump_instance_parameter('serial.port', serial_tcp_port)

        # run vm
        inst = hc.inst
        cmd = ["%s -m %d -smp %d -name vdc-%s -vnc :%d",
               "-pidfile %s",
               "-daemonize",
               "-monitor telnet:127.0.0.1:%d,server,nowait",
               "-serial telnet:127.0.0.1:%d,server,nowait",
               "-no-shutdown",
               driver_configuration.qemu_options,
               ]
        args=[driver_configuration.qemu_path,
              inst[:memory_size],
              inst[:cpu_cores],
              inst[:uuid],
              vnc_tcp_port - 5900, # KVM -vnc offsets 5900
              File.expand_path('kvm.pid', hc.inst_data_dir),
              monitor_tcp_port,
              serial_tcp_port
             ]

        cmd << "-drive file=%s,media=disk,boot=on,index=0,cache=none,if=#{drive_model(hc)}"
        args << hc.os_devpath
        cmd << "-drive file=%s,media=disk,index=1,cache=none,if=#{drive_model(hc)}"
        args << hc.metadata_img_path

        vifs = inst[:vif]
        if !vifs.empty?
          vifs.sort {|a, b|  a[:device_index] <=> b[:device_index] }.each { |vif|
            cmd << "-net nic,vlan=#{vif[:device_index].to_i},macaddr=%s,model=#{nic_model(hc)},addr=%x -net tap,vlan=#{vif[:device_index].to_i},ifname=%s,script=no,downscript=no"
            args << vif[:mac_addr].unpack('A2'*6).join(':')
            args << (KVM_NIC_PCI_ADDR_OFFSET + vif[:device_index].to_i)
            args << vif[:uuid]
          }
        end
        sh(cmd.join(' '), args)

        vifs.each { |vif|
          if vif[:ipv4] and vif[:ipv4][:network]
            sh("/sbin/ip link set %s up", [vif[:uuid]])
            sh("#{Dcmgr.conf.brctl_path} addif %s %s", [bridge_if_name(vif[:ipv4][:network][:dc_network]), vif[:uuid]])
          end
        }

        sleep 1
      end

      def terminate_instance(hc)
        poweroff_instance(hc)
      end

      def reboot_instance(hc)
        inst = hc.inst
        connect_monitor(hc) { |t|
          t.cmd("system_reset")
          # When the guest initiate halt/poweroff the KVM might become
          # "paused" status. At that time, "system_reset" command does
          # not work as it is an ACPI signal. The "cont" command allows
          # to bring the status back to running in this case.
          # It has no effect if the status is kept running already.
          t.cmd('cont')
        }
      end

      def attach_volume_to_guest(hc)
        # pci_devddr consists of three hex numbers with colon separator.
        #  dom <= 0xffff && bus <= 0xff && val <= 0x1f
        # see: qemu-0.12.5/hw/pci.c
        # /*
        # * Parse [[<domain>:]<bus>:]<slot>, return -1 on error
        # */
        # static int pci_parse_devaddr(const char *addr, int *domp, int *busp, unsigned *slotp)
        pci_devaddr = nil
        inst = hc.inst

        sddev = File.expand_path(File.readlink(hc.os_devpath), '/dev/disk/by-path')
        connect_monitor(hc) { |t|
          # success message:
          #   OK domain 0, bus 0, slot 4, function 0
          # error message:
          #   failed to add file=/dev/xxxx,if=virtio
          c = t.cmd("pci_add auto storage file=#{sddev},if=#{drive_model(hc)},cache=off")
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

      def detach_volume_from_guest(hc)
        inst = hc.inst
        vol = hc.vol
        pci_devaddr = vol[:guest_device_name]

        connect_monitor(hc) { |t|
          t.cmd("pci_del #{pci_devaddr}")

          #
          #  Bus  0, device   4, function 0:
          #    SCSI controller: PCI device 1af4:1001
          #      IRQ 0.
          #      BAR0: I/O at 0x1000 [0x103f].
          #      BAR1: 32 bit memory at 0x08000000 [0x08000fff].
          #      id ""
          pci_devaddr = pci_devaddr.split(':')
          pass=false
          tryagain do
            sleep 1
            pass = t.shell_result("info pci").split(/\n/).grep(/\s+Bus\s+#{pci_devaddr[1].to_i(16)}, device\s+#{pci_devaddr[2].to_i(16)}, function/).empty?
          end
          raise "Detached disk device still be attached in qemu-kvm: #{pci_devaddr.join(':')}" if pass == false
        }
      end

      def check_instance(i)
        kvm_pid_path = File.expand_path("#{i}/kvm.pid", Dcmgr.conf.vm_data_dir)
        unless File.exists?(kvm_pid_path)
          raise "Unable to find the kvm.pid file: #{i}"
        end
        pid = File.read(kvm_pid_path).to_i
        unless File.exists?(File.expand_path(pid.to_s, '/proc'))
          raise "Unable to find the pid of kvm process: #{pid}"
        end
      end

      def poweroff_instance(hc)
        begin
          connect_monitor(hc) { |t|
            t.cmd("quit")
          }
        rescue Errno::ECONNRESET => e
          # succssfully terminated the process
        rescue => e
          kvm_pid = File.read(File.expand_path('kvm.pid', hc.inst_data_dir))
          if kvm_pid.nil? || kvm_pid == ''
            kvm_pid=`pgrep -u root -f vdc-#{hc.inst_id}`
          end
          if kvm_pid.to_s =~ /^\d+$/
            sh("/bin/kill -9 #{kvm_pid}") rescue logger.error($!)
          else
            logger.error("Can not find the KVM process. Skipping: #{hc.inst_id}")
          end
        end
      end

      private
      # Establish telnet connection to KVM monitor console
      def connect_monitor(hc, &blk)
        port = File.read(File.expand_path('monitor.port', hc.inst_data_dir)).to_i
        logger.debug("monitor port number: #{port}")
        begin
          telnet = ::Net::Telnet.new("Host" => "localhost",
                                     "Port"=>port.to_s,
                                     "Prompt" => /\n\(qemu\) \z/,
                                     "Timeout" => 60,
                                     "Waittime" => 0.2)

          # Add helper method for parsing response from qemu monitor shell.
          telnet.instance_eval {
            def shell_result(cmdstr)
              ret = ""
              hit = false
              self.cmd(cmdstr).split("\n(qemu) ").each { |i|
                i.split("\n").each { |i2|

                  if i2 =~ /#{cmdstr}/
                    hit = true
                    next
                  end
                  ret += ("\n" + i2) if hit
                }
              }
              ret.sub(/^\n/, '')
            end
          }

          blk.call(telnet)
        ensure
          telnet.close
        end
      end

      TCP_PORT_MAX=65535
      PORT_OFFSET=9000
      # Randomly choose unused local tcp port number.
      def pick_tcp_listen_port
        # Support only for Linux netstat output.
        l=`/bin/netstat -nlt`.split("\n")
        # take out two header lines.
        l.shift
        l.shift

        listen_ports = {}

        l.each { |n|
          m = n.split(/\s+/)
          if m[0] == 'tcp'
            ip, port = m[3].split(':')
            listen_ports[port.to_i]=ip
          elsif m[0] == 'tcp6'
            ary = m[3].split(':')
            port = ary.pop
            listen_ports[port.to_i]=ary.join(':')
          end
        }


        begin
          new_port = (PORT_OFFSET + rand(TCP_PORT_MAX - PORT_OFFSET))
        end until(!listen_ports.has_key?(new_port))
        new_port
      end

      def drive_model(hc)
        hc.inst[:image][:features][:virtio] ? 'virtio' : 'scsi'
      end

      def nic_model(hc)
        hc.inst[:image][:features][:virtio] ? 'virtio' : 'e1000'
      end

      Task::Tasklet.register(self.new)
    end
  end
end
