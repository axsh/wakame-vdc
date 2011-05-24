module Dcmgr
  module Drivers
    class Lxc
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def create_config(inst, inst_data_dir, os_devpath)
        # create config file i-xxxxxxxx.log
        inst_id = inst[:uuid]
        vnic = inst[:instance_nics].first
        mac_addr = vnic[:mac_addr].unpack('A2'*6).join(':')
        
        config_name = "#{inst_data_dir}/config.#{inst_id}"
        # check config file
        if File.exist?(config_name)
          sh("rm #{config_name}")
        end

        config = File.open(config_name, 'w')
        config.puts "lxc.utsname = #{inst_id}"
        config.puts "lxc.tty = 4"
        config.puts "lxc.network.type = veth"
        config.puts "lxc.network.flags = up"
        config.puts "lxc.network.link = br0"
        config.puts "lxc.network.name = eth0"
        config.puts "lxc.network.mtu = 1500"
        config.puts "lxc.network.hwaddr = #{mac_addr}"
        config.puts "lxc.network.ipv4 = 0.0.0.0"
        config.puts "lxc.rootfs = #{inst_data_dir}/rootfs"
        config.puts "lxc.cgroup.devices.deny = a"
        config.puts "lxc.cgroup.devices.allow = c 1:3 rwm"
        config.puts "lxc.cgroup.devices.allow = c 1:5 rwm"
        config.puts "lxc.cgroup.devices.allow = c 5:1 rwm"
        config.puts "lxc.cgroup.devices.allow = c 5:0 rwm"
        config.puts "lxc.cgroup.devices.allow = c 4:0 rwm"
        config.puts "lxc.cgroup.devices.allow = c 4:1 rwm"
        config.puts "lxc.cgroup.devices.allow = c 1:9 rwm"
        config.puts "lxc.cgroup.devices.allow = c 1:8 rwm"
        config.puts "lxc.cgroup.devices.allow = c 136:* rwm"
        config.puts "lxc.cgroup.devices.allow = c 5:2 rwm"
        config.puts "lxc.cgroup.devices.allow = c 254:0 rwm"
        unless inst[:volume].nil?
          inst[:volume].each { |volid, v|
            vol_id = volid
            vol = v
            unless v[:guest_device_name].nil?
              config.puts "lxc.cgroup.devices.allow = b #{v[:guest_device_name]} rwm"
            else
              os_devpath = v[:host_device_name] unless v[:host_device_name].nil?
              sddev = File.expand_path(File.readlink(os_devpath), '/dev/disk/by-path')
              # find major number and minor number to device file
              stat = File.stat(sddev)
              config.puts "lxc.cgroup.devices.allow = b #{stat.rdev_major}:#{stat.rdev_minor} rwm"
            end
          }
        end
        config.close
        config_name
      end

      def run_instance(inst, data)
        # run lxc
        os_devpath = data[:os_devpath]
        inst_data_dir = data[:inst_data_dir]

        # check mount point
        mount_point = "#{inst_data_dir}/rootfs"
        unless File.exist?(mount_point)
          sh("mkdir #{mount_point}")
        end

        cmd = "mount %s %s"
        args = [os_devpath, mount_point]
        if inst[:image][:boot_dev_type] == 2
          cmd += " -o loop"
        end
        sh(cmd, args)

        config_name = create_config(inst, inst_data_dir, os_devpath)

        sh("lxc-create -f %s -n %s", [config_name, inst[:uuid]])
        sh("lxc-start -n %s -l DEBUG -o %s/%s.log -d", [inst[:uuid], inst_data_dir, inst[:uuid]])
      end

      def terminate_instance(inst_id, inst_data_dir)
        sh("lxc-stop -n #{inst_id}")
        sh("lxc-destroy -n #{inst_id}")
        sh("umount #{inst_data_dir}/rootfs")
      end

      def reboot_instance(inst, inst_data_dir)
        os_devpath = nil
        if inst[:image][:boot_dev_type] == 1
          inst[:volume].each{|volid, v|
            os_devpath = v[:host_device_name] if v[:boot_dev] == 1
          }
        else
          os_devpath = "#{inst_data_dir}/#{inst[:uuid]}"
        end
        terminate_instance(inst[:uuid], inst_data_dir)
        run_instance(inst, {:os_devpath=>os_devpath,
                       :inst_data_dir=>inst_data_dir})
      end

      def attach_volume_to_guest(inst, data)
        sddev = File.expand_path(File.readlink(data[:linux_dev_path]), '/dev/disk/by-path')

        # find major number and minor number to device file
        stat = File.stat(sddev)
        devnum = [stat.rdev_major,stat.rdev_minor].join(':')
        
        sh("echo \"b #{devnum} rwm\" > /cgroup/#{inst[:uuid]}/devices.allow")

        config_name = "#{data[:inst_data_dir]}/config.#{inst[:uuid]}"
        config = File.open(config_name, 'r')
        data = config.readlines
        config.close
        config = File.open(config_name, 'w')
        config.write data
        config.puts "lxc.cgroup.devices.allow = b #{devnum} rwm"
        config.close
        devnum
      end

      def detach_volume_from_guest(guest_device_name, data)
        devnum = guest_device_name
        sh("echo \"b #{devnum} rwm\" > /cgroup/#{data[:inst_id]}/devices.deny")

        config_name = "#{data[:inst_data_dir]}/config.#{data[:inst_id]}"
        config = File.open(config_name, 'r')
        data = config.readlines.select {|f| f != "lxc.cgroup.devices.allow = b #{devnum} rwm\n" }
        config.close
        config = File.open(config_name, 'w+')
        config.write data
        config.close
      end

    end
  end
end
