module Dcmgr
  module Drivers
    class Lxc < Hypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def create_config
        # create config file i-xxxxxxxx.log
        inst_id = @inst[:uuid]
        vnic = @inst[:instance_nics].first
        mac_addr = vnic[:mac_addr].unpack('A2'*6).join(':')
        
        config_name = "#{@inst_data_dir}/config.#{inst_id}"
        # check config file
        if File.exist?(config_name)
          sh("rm #{config_name}")
        end

        config = File.open(config_name, 'w')
        config.puts "lxc.utsname = #{inst_id}"
        config.puts "lxc.tty = 4"
        config.puts "lxc.pts = 1024"
        config.puts "lxc.network.type = veth"
        config.puts "lxc.network.veth.pair = #{vnic[:uuid]}"
        config.puts "lxc.network.flags = up"
        config.puts "lxc.network.link = #{@bridge_if}"
        config.puts "lxc.network.hwaddr = #{mac_addr}"
        config.puts "lxc.rootfs = #{@inst_data_dir}/rootfs"
        config.puts "lxc.mount = #{@inst_data_dir}/fstab"
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
        config.puts "lxc.cgroup.devices.allow = c 10:232 rwm"
        config.puts "lxc.cgroup.devices.allow = c 10:200 rwm"
        unless @inst[:volume].nil?
          @inst[:volume].each { |volid, v|
            vol_id = volid
            vol = v
            unless v[:guest_device_name].nil?
              config.puts "lxc.cgroup.devices.allow = b #{v[:guest_device_name]} rwm"
            else
              @os_devpath = v[:host_device_name] unless v[:host_device_name].nil?
              sddev = File.expand_path(File.readlink(@os_devpath), '/dev/disk/by-path')
              # find major number and minor number to device file
              stat = File.stat(sddev)
              config.puts "lxc.cgroup.devices.allow = b #{stat.rdev_major}:#{stat.rdev_minor} rwm"
            end
          }
        end
        config.close
        config_name
      end

      def create_fstab
        config_name = "#{@inst_data_dir}/fstab"
        config = File.open(config_name, "w")
        config.puts "proc #{@inst_data_dir}/rootfs/proc proc nodev,noexec,nosuid 0 0"
        config.puts "devpts #{@inst_data_dir}/rootfs/dev/pts devpts defaults 0 0"
        config.puts "sysfs #{@inst_data_dir}/rootfs/sys sysfs defaults 0 0"
        config.close
      end

      def setup_container
        sh("echo \"127.0.0.1 localhost #{@inst_id}\" > #{@inst_data_dir}/rootfs/etc/hosts")
        sh("echo \"#{@inst_id}\" > #{@inst_data_dir}/rootfs/etc/hostname")
      end

      def run_instance(hc)
        # run lxc
        @inst = hc.inst
        @bridge_if = hc.bridge_if
        @inst_data_dir = hc.inst_data_dir
        @os_devpath = hc.os_devpath
        if @os_devpath.nil?
          if @inst[:image][:boot_dev_type] == 1
            @inst[:volume].each{|volid, v|
              @os_devpath = v[:host_device_name] if v[:boot_dev] == 1
            }
          else
            @os_devpath = "#{@inst_data_dir}/#{hc.inst_id}"
          end
        end
        # check mount point
        mount_point = "#{@inst_data_dir}/rootfs"
        unless File.exist?(mount_point)
          sh("mkdir #{mount_point}")
        end

        cmd = "mount %s %s"
        args = [@os_devpath, mount_point]
        if @inst[:image][:boot_dev_type] == 2
          cmd += " -o loop"
        end
        sh(cmd, args)

        config_name = create_config
        create_fstab
        setup_container

        sh("lxc-create -f %s -n %s", [config_name, @inst[:uuid]])
        sh("sudo lxc-start -n %s -d -l DEBUG -o %s/%s.log", [@inst[:uuid], @inst_data_dir, @inst[:uuid]])
      end

      def terminate_instance(hc)
        sh("lxc-stop -n #{hc.inst_id}")
        sh("lxc-destroy -n #{hc.inst_id}")
        sh("umount #{hc.inst_data_dir}/rootfs")
      end

      def reboot_instance(hc)
        inst = hc.inst
        terminate_instance(hc)
        run_instance(hc)
      end

      def attach_volume_to_guest(hc)
        inst_id = hc.inst_id
        sddev = File.expand_path(File.readlink(hc.os_devpath), '/dev/disk/by-path')

        # find major number and minor number to device file
        stat = File.stat(sddev)
        devnum = [stat.rdev_major,stat.rdev_minor].join(':')
        
        sh("echo \"b #{devnum} rwm\" > /cgroup/#{inst_id}/devices.allow")
        sh("mknod #{hc.inst_data_dir}/rootfs#{sddev} -m 660 b #{stat.rdev_major} #{stat.rdev_minor}")

        config_name = "#{hc.inst_data_dir}/config.#{inst_id}"
        config = File.open(config_name, 'r')
        data = config.readlines
        config.close
        config = File.open(config_name, 'w')
        config.write data
        config.puts "lxc.cgroup.devices.allow = b #{devnum} rwm"
        config.close
        devnum
      end

      def detach_volume_from_guest(hc)
        inst_id = hc.inst_id
        vol = hc.vol
        sddev = File.expand_path(File.readlink(vol[:host_device_name]), '/dev/disk/by-path')
        devnum = vol[:guest_device_name]

        sh("echo \"b #{devnum} rwm\" > /cgroup/#{inst_id}/devices.deny")
        sh("rm -rf #{hc.inst_data_dir}/rootfs#{sddev}")

        config_name = "#{hc.inst_data_dir}/config.#{inst_id}"
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
