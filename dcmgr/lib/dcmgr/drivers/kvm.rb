# -*- coding: utf-8 -*-

require 'net/telnet'

module Dcmgr
  module Drivers
    class Kvm < LinuxHypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper

      # API policy information for QEMU-KVM hypervisor.
      class Policy < HypervisorPolicy
        DEVNAME_REGEXP=[/^sd([a-z]+)$/,
                        /^hd([a-z]+)$/,
                        /^vd([a-z]+)$/
                       ].freeze

        def validate_instance_model(instance)
        end

        def validate_volume_model(volume)
          if !volume.guest_device_name.nil?
            unless DEVNAME_REGEXP.find { |r| r =~ volume.guest_device_name.downcase }
              raise ValidationError, "InvalidParameter: guest_device_name #{volume.guest_device_name}"
            end
          end
        end

        def on_associate_volume(instance, volume)
          if instance.boot_volume_id == volume.canonical_uuid && volume.guest_device_name.nil?
            # set device name as boot drive.
            volume.guest_device_name =
              if instance.image.features[:virtio]
                'vda'
              else
                'sda'
              end
          elsif volume.guest_device_name.nil?
            devnames = instance.volume_guest_device_names
            # sdb,vdb,hdb are reserved for metadata drive. extra volumes
            # should starts from third device number.
            devnames.push( instance.boot_volume.guest_device_name.succ )
            volume.guest_device_name = find_candidate_device_name(devnames)
          end
        end

        private
        def find_candidate_device_name(device_names)
          # sort %w(hdaz hdaa hdc hdz hdn) => ["hdc", "hdn", "hdz", "hdaa", "hdaz"]
          device_names = device_names.sort{|a,b| a.size == b.size ? a <=> b :  a.size <=> b.size }
          return nil if device_names.empty?
          # find candidate device name from unused successor of device_names.
          #   %w(hdaz hdaa hdc hdz hdn) => hdd (= "hdc".succ)
          device_names.zip(device_names.dup.tap(&:shift)).inject(device_names.first) {|r,l|  r.succ == l.last ? l.last : r }.succ
        end
      end

      def self.policy
        Policy.new
      end

      def self.local_store_class
        KvmLocalStore
      end

      def_configuration do
        # set Dcmgr::Drivers::Kvm constant.
        @@configuration_source_class = ::Module.nesting.first

        param :qemu_path, :default=>proc { ||
          if File.exists?('/etc/debian_version')
            '/usr/bin/kvm'
          else
            '/usr/libexec/qemu-kvm'
          end
        }

        param :qemu_options, :default=>'-no-kvm-pit-reinjection'

        param :serial_port_options, :default=>'telnet:127.0.0.1:%d,server,nowait'
        param :vnc_options, :default=>'127.0.0.1:%d'
        param :incoming_ip

        param :windows_configuring_status_sleeptime, default: 2
        param :windows_configuring_status_timeout, default: 60
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

      def get_windows_password_hash(hc)
        wait_for_kvm_termination(hc)
        mount_point = "#{hc.inst_data_dir}/tmp_metadata_mnt"

        FileUtils.mkdir(mount_point)
        mount_metadata_drive(hc, mount_point)
        password_hash = read_password_from_metadata_drive(mount_point)
        umount_metadata_drive(hc, mount_point)

        poweron_instance(hc)

        password_hash
      end

      def read_password_from_metadata_drive(mount_point)
        "temporary fake password"
      end

      def wait_for_kvm_termination(hc)
        pid = File.read(File.expand_path('kvm.pid', hc.inst_data_dir)).to_i
        logger.debug "Waiting for instance %s (process %s) to terminate" %
          [hc.inst[:uuid], pid]

        # We are doing this weirdness because we couldn't use Process.waitpid
        # because kvm is not a child process. This driver creates a run.sh script
        # and runs that which in turn runs kvm.
        time_passed = 0
        sleeptime = driver_configuration.windows_configuring_status_sleeptime
        timeout = driver_configuration.windows_configuring_status_timeout
        begin
         while true
           sh "ps -p #{pid}"
           sleep sleeptime
           time_passed += sleeptime

           if time_passed > timeout
            raise "Windows took too long to configure itself. Waited #{timeout} seconds"
           end
         end
        rescue Dcmgr::Helpers::CliHelper::ShellRunner::CommandError
          # If we get this error, it means the kvm process has terminated
        end
      end

      def run_instance(hc)
        poweron_instance(hc)
      end

      def poweron_instance(hc)
        qemu_command = build_qemu_command(hc)
        sh(qemu_command)

        run_sh = <<RUN_SH
#!/bin/bash
#{qemu_command}
RUN_SH

        hc.inst[:vif].each do |vif|
          if vif[:ipv4] and vif[:ipv4][:network]
            sh("/sbin/ip link set %s up" % [vif_uuid(vif)])
            bridge = bridge_if_name(vif[:ipv4][:network][:dc_network])
            attach_vif_cmd = attach_vif_to_bridge(bridge, vif)

            sh(attach_vif_cmd)

            run_sh += ("/sbin/ip link set %s up" % [vif_uuid(vif)])
            run_sh += (attach_vif_cmd)
          end
        end

        # Dump as single shell script file to help failure recovery
        # process of the user instance.
        begin
          hc.dump_instance_parameter('run.sh', run_sh)
          File.chmod(0755, File.expand_path('run.sh', hc.inst_data_dir))
        rescue => e
          hc.logger.warn("Failed to export run.sh rescue script: #{e}")
        end
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

      module Standard
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
      end

      # qemu on RHEL6 uses non-standarnd monitor command names for
      # drive_add and drive_del.
      #   __com.redhat_drive_add
      #   __com.redhat_drive_del
      module RHEL6
        def attach_volume_to_guest(hc)
          connect_monitor(hc) { |t|
            drive_opts = with_drive_extra_opts("file=#{hc.volume_path(hc.vol)},id=#{hc.vol[:uuid]}-drive")
            t.cmd("__com.redhat_drive_add #{drive_opts}")
            t.cmd("device_add " + qemu_drive_device_options(hc, hc.vol))
          }
        end

        def detach_volume_from_guest(hc)
          connect_monitor(hc) { |t|
            t.cmd("device_del " + hc.vol[:uuid])
            t.cmd("__com.redhat_drive_del #{hc.vol[:uuid]}-drive")
          }
        end
      end
      include RHEL6

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

      def soft_poweroff_instance(hc)
        begin
          connect_monitor(hc) { |t|
            t.cmd("system_poweroff")
          }
        rescue Errno::ECONNRESET => e
          # succssfully terminated the process
        end
      end

      include Hypervisor::MigrationLive

      def run_migration_instance(hc)
        qemu_command = build_qemu_command(hc)

        migration_tcp_port = pick_tcp_listen_port

        sh(qemu_command + " -incoming tcp:#{driver_configuration.incoming_ip}:#{migration_tcp_port}")

        run_sh = <<RUN_SH
#!/bin/bash
#{qemu_command}
RUN_SH

        hc.inst[:vif].each do |vif|
          if vif[:ipv4] and vif[:ipv4][:network]
            sh("/sbin/ip link set %s up" % [vif_uuid(vif)])
            bridge = bridge_if_name(vif[:ipv4][:network][:dc_network])
            attach_vif_cmd = attach_vif_to_bridge(bridge, vif)

            sh(attach_vif_cmd)

            run_sh += ("/sbin/ip link set %s up" % [vif_uuid(vif)])
            run_sh += (attach_vif_cmd)
          end
        end

        # Dump as single shell script file to help failure recovery
        # process of the user instance.
        begin
          hc.dump_instance_parameter('run.sh', run_sh)
          File.chmod(0755, File.expand_path('run.sh', hc.inst_data_dir))
        rescue => e
          hc.logger.warn("Failed to export run.sh rescue script: #{e}")
        end

        {:listen_ip=>driver_configuration.incoming_ip, :port=>migration_tcp_port}
      end

      def start_migration(hc, dest_params)
        connect_monitor(hc) do |t|
          t.cmd("migrate -d tcp:#{dest_params[:listen_ip]}:#{dest_params[:port].to_i}")
        end
      end

      def watch_migration(hc)
        connect_monitor(hc) do |t|
          while line = t.cmd("info migrate")
            p line
            if line =~ /\nMigration status: (\w+)/
              case $1
              when 'active'
                sleep 1
              when 'completed'
                break
              end
            end
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

      LINUX_DEVICE_INDEX_MAP={}
      ('a'..'z').to_a.each_with_index {|i, idx|
        LINUX_DEVICE_INDEX_MAP[i]=idx
      }
      LINUX_DEVICE_INDEX_MAP.freeze

      # calc drive index from guest drive device name.
      def drive_index(device_name)
        case device_name.downcase
        when /sd([a-z]+)/, /vd([a-z]+)/, /xvd([a-z]+)/, /hd([a-z]+)/
          $1.split('').inject(0) { |r,i| r + LINUX_DEVICE_INDEX_MAP[i] }.to_i
        else
          raise "Unsupported device name: #{device_name}"
        end
      end

      # Returns -device options for -drive.
      def qemu_drive_device_options(hc, volume)
        device_model = if hc.inst[:image][:features][:virtio]
                         # provides virtio block disk.
                         'virtio-blk-pci'
                       else
                         # attach as IDE disk. The qemu does not
                         # have normal scsi controller.
                         'ide-drive'
                       end
        drive_idx = drive_index(volume[:guest_device_name])
        
        option_str = "#{device_model},id=#{volume[:uuid]},drive=#{volume[:uuid]}-drive,serial=#{volume[:uuid]}"
        if hc.inst[:boot_volume_id] == volume[:uuid]
          option_str += ',bootindex=0'
        end

        case device_model
        when 'virtio-blk-pci'
          # virtio-blk consumes a pci address per device.
          option_str += ",bus=pci.0,addr=#{'0x' + ('%x' % (drive_idx + 4))}"
        when 'ide-drive'
        end

        option_str
      end

      def build_qemu_options(hc, monitor_tcp_port, opts={})
        inst = hc.inst
        cmd = ["-m %d",
               "-smp %d",
               "-name vdc-%s",
               "-pidfile %s",
               "-daemonize",
               "-monitor telnet:127.0.0.1:%d,server,nowait",
               driver_configuration.qemu_options,
               ]
        args=[inst[:memory_size],
              inst[:cpu_cores],
              inst[:uuid],
              File.expand_path('kvm.pid', hc.inst_data_dir),
              monitor_tcp_port,
             ]

        if driver_configuration.vnc_options && opts[:vnc_tcp_port]
          # KVM -vnc port number offset is 5900
          cmd << '-vnc ' + (driver_configuration.vnc_options.to_s % [opts[:vnc_tcp_port].to_i - 5900])
        end

        if driver_configuration.serial_port_options && opts[:serial_tcp_port]
          cmd << '-serial ' + (driver_configuration.serial_port_options.to_s % [opts[:serial_tcp_port].to_i])
        end

        inst[:volume].each { |vol_id, v|
          cmd << with_drive_extra_opts("-drive file=%s,id=#{v[:uuid]}-drive,if=none")
          args << hc.volume_path(v)
          cmd << "-device " + qemu_drive_device_options(hc, v)
          # attach metadata drive
          if inst[:boot_volume_id] == v[:uuid]
            cmd << with_drive_extra_opts("-drive file=#{hc.metadata_img_path},id=metadata-drive,if=none")
            # guess secondary drive device name for metadata drive.
            cmd << "-device " + qemu_drive_device_options(hc, {guest_device_name: v[:guest_device_name].succ, uuid: 'metadata'})
          end
        }

        vifs = inst[:vif]
        if !vifs.empty?
          vifs.sort {|a, b|  a[:device_index] <=> b[:device_index] }.each { |vif|
            cmd << "-net nic,vlan=#{vif[:device_index].to_i},macaddr=%s,model=#{nic_model(hc)},addr=%x -net tap,vlan=#{vif[:device_index].to_i},ifname=%s,script=no,downscript=no"
            args << vif[:mac_addr].unpack('A2'*6).join(':')
            args << (KVM_NIC_PCI_ADDR_OFFSET + vif[:device_index].to_i)
            args << vif_uuid(vif)
          }
        end

        cmd.join(' ') % args
      end

      def build_qemu_command(hc)
        # tcp listen ports for KVM monitor and VNC console
        monitor_tcp_port = pick_tcp_listen_port
        hc.dump_instance_parameter('monitor.port', monitor_tcp_port)

        opts = {}
        # run vm
        inst = hc.inst
        if driver_configuration.vnc_options
          opts[:vnc_tcp_port] = pick_tcp_listen_port
          hc.dump_instance_parameter('vnc.port', opts[:vnc_tcp_port])
        end

        if driver_configuration.serial_port_options
          opts[:serial_tcp_port] = pick_tcp_listen_port
          hc.dump_instance_parameter('serial.port', opts[:serial_tcp_port])
        end

        "#{driver_configuration.qemu_path} #{build_qemu_options(hc, monitor_tcp_port, opts)}"
      end

      Task::Tasklet.register(self) {
        self.new
      }

      # Add extra options to -drive parameter.
      # mainly for none=cache does not work some filesystems without O_DIRECT.
      def with_drive_extra_opts(base)
        [base, driver_configuration.local_store.drive_extra_options].compact.join(',')
      end
    end
  end
end
