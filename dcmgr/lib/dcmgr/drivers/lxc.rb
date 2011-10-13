# -*- coding: utf-8 -*-

require 'erb'

module Dcmgr
  module Drivers
    class Lxc < Hypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def run_instance(ctx)
        # run lxc
        @os_devpath = ctx.os_devpath
        if @os_devpath.nil?
          if ctx.inst[:image][:boot_dev_type] == 1
            ctx.inst[:volume].each{ |vol_id, vol|
              @os_devpath = vol[:host_device_name] if vol[:boot_dev] == 1
            }
          else
            @os_devpath = "#{ctx.inst_data_dir}/#{ctx.inst_id}"
          end
        end
        # check mount point
        mount_point = "#{ctx.inst_data_dir}/rootfs"
        Dir.mkdir(mount_point) unless File.exists?(mount_point)

        cmd = "mount %s %s"
        args = [@os_devpath, mount_point]
        if ctx.inst[:image][:boot_dev_type] == 2
          cmd += " -o loop"
        end
        sh(cmd, args)

        config_name = create_config(ctx)
        create_fstab(ctx)
        setup_container(ctx)
        mount_cgroup

        # Ubuntu 10.04.3 LTS
        # Linux ubuntu 2.6.38-10-generic #46~lucid1-Ubuntu SMP Wed Jul 6 18:40:11 UTC 2011 i686 GNU/Linux
        # Linux ubuntu 2.6.38-8-server #42-Ubuntu SMP Mon Apr 11 03:49:04 UTC 2011 x86_64 GNU/Linux
        # lxc 0.7.4-0ubuntu7
        #
        # Ubuntu-10.04.3 on Virtualbox-4.0.12 r72916 on Windows-7
        # Ubuntu-10.10
        #
        # > lxc-start 1311803515.629 ERROR    lxc_start - inherited fd 3 on pipe:[58281]
        # > lxc-start 1311803515.629 ERROR    lxc_start - inherited fd 4 on pipe:[58281]
        # > lxc-start 1311803515.629 ERROR    lxc_start - inherited fd 6 on socket:[58286]
        #
        # http://comments.gmane.org/gmane.linux.kernel.containers.lxc.general/912
        # http://comments.gmane.org/gmane.linux.kernel.containers.lxc.general/1400
        lxc_version = `lxc-version`.chomp.split(': ').last
        logger.debug("lxc-version: #{lxc_version}")

        sh("lxc-create -f %s -n %s", [config_name, ctx.inst[:uuid]])
        sh("lxc-start -n %s -d -l DEBUG -o %s/%s.log 3<&- 4<&- 6<&-", [ctx.inst[:uuid], ctx.inst_data_dir, ctx.inst[:uuid]])
      end

      def terminate_instance(ctx)
        sh("lxc-stop -n #{ctx.inst_id}")
        sh("lxc-destroy -n #{ctx.inst_id}")
        sh("umount #{ctx.inst_data_dir}/rootfs")
      end

      def reboot_instance(ctx)
        sh("lxc-stop -n #{ctx.inst[:uuid]}")
        sh("lxc-start -n %s -d -l DEBUG -o %s/%s.log 3<&- 4<&- 6<&-", [ctx.inst[:uuid], ctx.inst_data_dir, ctx.inst[:uuid]])
      end

      def attach_volume_to_guest(ctx)
        sddev = File.expand_path(File.readlink(ctx.os_devpath), '/dev/disk/by-path')

        # find major number and minor number to device file
        stat = File.stat(sddev)
        devnum = [stat.rdev_major,stat.rdev_minor].join(':')

        sh("echo \"b #{devnum} rwm\" > /cgroup/#{ctx.inst_id}/devices.allow")
        logger.debug("Makinging new block device: #{ctx.inst_data_dir}/rootfs#{sddev}")
        sh("mknod #{ctx.inst_data_dir}/rootfs#{sddev} -m 660 b #{stat.rdev_major} #{stat.rdev_minor}")

        config_name = "#{ctx.inst_data_dir}/config.#{ctx.inst_id}"
        config = File.open(config_name, 'r')
        data = config.readlines
        config.close
        config = File.open(config_name, 'w')
        config.write data
        config.puts "lxc.cgroup.devices.allow = b #{devnum} rwm"
        config.close
        devnum
      end

      def detach_volume_from_guest(ctx)
        vol = ctx.vol
        sddev = File.expand_path(File.readlink(vol[:host_device_name]), '/dev/disk/by-path')
        devnum = vol[:guest_device_name]

        sh("echo \"b #{devnum} rwm\" > /cgroup/#{ctx.inst_id}/devices.deny")
        logger.debug("Deleting block device: #{ctx.inst_data_dir}/rootfs#{sddev}")
        sh("rm #{ctx.inst_data_dir}/rootfs#{sddev}")

        config_name = "#{ctx.inst_data_dir}/config.#{ctx.inst_id}"
        config = File.open(config_name, 'r')
        data = config.readlines.select {|f| f != "lxc.cgroup.devices.allow = b #{devnum} rwm\n" }
        config.close
        config = File.open(config_name, 'w+')
        config.write data
        config.close
      end

      private
      def create_config(ctx)
        # create config file i-xxxxxxxx.log
        vnic = ctx.inst[:instance_nics].first
        mac_addr = vnic[:mac_addr].unpack('A2'*6).join(':')

        config_name = "#{ctx.inst_data_dir}/config.#{ctx.inst_id}"
        # check config file
        if File.exist?(config_name)
          sh("rm #{config_name}")
        end

        config = File.open(config_name, 'w')
        config.puts "lxc.network.type = veth"
        config.puts "lxc.network.link = #{ctx.bridge_if}"
        config.puts "lxc.network.flags = up"
        config.puts "lxc.utsname = #{ctx.inst_id}"
        config.puts ""
        config.puts "lxc.network.veth.pair = #{vnic[:uuid]}"
        config.puts "lxc.network.hwaddr = #{mac_addr}"
        config.puts ""
        config.puts "lxc.tty = 4"
        config.puts "lxc.pts = 1024"
        config.puts "lxc.rootfs = #{ctx.inst_data_dir}/rootfs"
        config.puts "lxc.mount = #{ctx.inst_data_dir}/fstab"
        config.puts ""
        config.puts "# /dev/null and zero"
        config.puts "lxc.cgroup.devices.deny = a"
        config.puts "lxc.cgroup.devices.allow = c 1:3 rwm"
        config.puts "lxc.cgroup.devices.allow = c 1:5 rwm"
        config.puts "# consoles"
        config.puts "lxc.cgroup.devices.allow = c 5:1 rwm"
        config.puts "lxc.cgroup.devices.allow = c 5:0 rwm"
        config.puts "lxc.cgroup.devices.allow = c 4:0 rwm"
        config.puts "lxc.cgroup.devices.allow = c 4:1 rwm"
        config.puts "# /dev/{,u}random"
        config.puts "lxc.cgroup.devices.allow = c 1:9 rwm"
        config.puts "lxc.cgroup.devices.allow = c 1:8 rwm"
        config.puts "lxc.cgroup.devices.allow = c 136:* rwm"
        config.puts "lxc.cgroup.devices.allow = c 5:2 rwm"
        config.puts "#rtc"
        config.puts "lxc.cgroup.devices.allow = c 254:0 rwm"
        config.puts "#kvm"
        config.puts "#lxc.cgroup.devices.allow = c 10:232 rwm"
        config.puts "#lxc.cgroup.devices.allow = c 10:200 rwm"

        unless ctx.inst[:volume].nil?
          ctx.inst[:volume].each { |vol_id, vol|
            unless vol[:guest_device_name].nil?
              config.puts "lxc.cgroup.devices.allow = b #{vol[:guest_device_name]} rwm"
            else
              @os_devpath = vol[:host_device_name] unless vol[:host_device_name].nil?
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

      def create_fstab(ctx)
        config_name = "#{ctx.inst_data_dir}/fstab"
        config = File.open(config_name, "w")
        config.puts "proc #{ctx.inst_data_dir}/rootfs/proc proc nodev,noexec,nosuid 0 0"
        config.puts "devpts #{ctx.inst_data_dir}/rootfs/dev/pts devpts defaults 0 0"
        config.puts "sysfs #{ctx.inst_data_dir}/rootfs/sys sysfs defaults 0 0"
        config.close
      end

      def setup_container(ctx)
        sh("echo \"127.0.0.1 localhost #{ctx.inst_id}\" > #{ctx.inst_data_dir}/rootfs/etc/hosts")
        sh("echo \"#{ctx.inst_id}\" > #{ctx.inst_data_dir}/rootfs/etc/hostname")
      end

      def mount_cgroup
        `mount -t cgroup | egrep -q cgroup`
        if $?.exitstatus != 0
          mount_point = "/cgroup"
          Dir.mkdir(mount_point) unless File.exists?(mount_point)
          sh("mount none -t cgroup #{mount_point}")
        end
      end

    end
  end
end
