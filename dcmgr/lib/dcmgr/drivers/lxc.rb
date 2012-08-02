# -*- coding: utf-8 -*-

require 'erb'

module Dcmgr
  module Drivers
    class Lxc < LinuxHypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def_configuration
      
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

        # metadata drive
        metadata_path = "#{ctx.inst_data_dir}/rootfs/metadata"
        Dir.mkdir(metadata_path) unless File.exists?(metadata_path)
        sh("mount -t vfat -o loop -o ro #{ctx.metadata_img_path} #{metadata_path}")

        config_path = create_config(ctx)
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

        sh("lxc-create -f %s -n %s", [config_path, ctx.inst[:uuid]])
        sh("lxc-start -n %s -d -l DEBUG -o %s/%s.log 3<&- 4<&- 6<&-", [ctx.inst[:uuid], ctx.inst_data_dir, ctx.inst[:uuid]])
      end

      def terminate_instance(ctx)
        sh("lxc-stop -n #{ctx.inst_id}")
        sh("lxc-destroy -n #{ctx.inst_id}")
        sh("umount #{ctx.inst_data_dir}/rootfs/metadata")
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

        config_path = "#{ctx.inst_data_dir}/config.#{ctx.inst_id}"
        File.open(config_path, 'a+') { |f|
          f.puts "lxc.cgroup.devices.allow = b #{devnum} rwm"
        }

        devnum
      end

      def detach_volume_from_guest(ctx)
        vol = ctx.vol
        sddev = File.expand_path(File.readlink(vol[:host_device_name]), '/dev/disk/by-path')
        devnum = vol[:guest_device_name]

        sh("echo \"b #{devnum} rwm\" > /cgroup/#{ctx.inst_id}/devices.deny")
        logger.debug("Deleting block device: #{ctx.inst_data_dir}/rootfs#{sddev}")
        sh("rm #{ctx.inst_data_dir}/rootfs#{sddev}")

        config_path = "#{ctx.inst_data_dir}/config.#{ctx.inst_id}"
        config_body = File.open(config_path, 'r') { |f|
          f.readlines.select {|line| line != "lxc.cgroup.devices.allow = b #{devnum} rwm\n" }
        }
        File.open(config_path, 'w') { |f|
          f.write config_body
        }
      end

      def check_instance(i)
        container_status = `lxc-info -n #{i}`.chomp.split(" ")[2]
        if container_status != "RUNNING"
          raise "Unable to find the lxc container: #{i}"
        end
      end

      private
      def create_config(ctx)
        # create config file i-xxxxxxxx.log

        config_path = "#{ctx.inst_data_dir}/config.#{ctx.inst_id}"
        # check config file
        if File.exist?(config_path)
          sh("rm #{config_path}")
        end

        vifs = ctx.inst[:vif]

        File.open(config_path, 'w') { |f|
          f.puts "lxc.utsname = #{ctx.inst_id}"
          f.puts ""
          if !vifs.empty?
            vifs.sort {|a, b|  a[:device_index] <=> b[:device_index] }.each { |vif|
              f.puts "lxc.network.type = veth"
              if vif[:ipv4]
                f.puts "lxc.network.link = #{bridge_if_name(vif[:ipv4][:network][:dc_network])}"
              end
              f.puts "lxc.network.veth.pair = #{vif[:uuid]}"
              f.puts "lxc.network.hwaddr = #{vif[:mac_addr].unpack('A2'*6).join(':')}"
              f.puts "lxc.network.flags = up"
            }
          end
          f.puts ""
          f.puts "lxc.tty = 4"
          f.puts "lxc.pts = 1024"
          f.puts "lxc.rootfs = #{ctx.inst_data_dir}/rootfs"
          f.puts "lxc.mount = #{ctx.inst_data_dir}/fstab"
          f.puts ""
          f.puts "lxc.cgroup.devices.deny = a"
          f.puts "# /dev/null and zero"
          f.puts "lxc.cgroup.devices.allow = c 1:3 rwm"
          f.puts "lxc.cgroup.devices.allow = c 1:5 rwm"
          f.puts "# consoles"
          f.puts "lxc.cgroup.devices.allow = c 5:1 rwm"
          f.puts "lxc.cgroup.devices.allow = c 5:0 rwm"
          f.puts "lxc.cgroup.devices.allow = c 4:0 rwm"
          f.puts "lxc.cgroup.devices.allow = c 4:1 rwm"
          f.puts "# /dev/{,u}random"
          f.puts "lxc.cgroup.devices.allow = c 1:9 rwm"
          f.puts "lxc.cgroup.devices.allow = c 1:8 rwm"
          f.puts "lxc.cgroup.devices.allow = c 136:* rwm"
          f.puts "lxc.cgroup.devices.allow = c 5:2 rwm"
          f.puts "#rtc"
          f.puts "lxc.cgroup.devices.allow = c 254:0 rwm"
          f.puts "#kvm"
          f.puts "#lxc.cgroup.devices.allow = c 10:232 rwm"
          f.puts "#lxc.cgroup.devices.allow = c 10:200 rwm"

          unless ctx.inst[:volume].nil?
            ctx.inst[:volume].each { |vol_id, vol|
              unless vol[:guest_device_name].nil?
                f.puts "lxc.cgroup.devices.allow = b #{vol[:guest_device_name]} rwm"
              else
                @os_devpath = vol[:host_device_name] unless vol[:host_device_name].nil?
                sddev = File.expand_path(File.readlink(@os_devpath), '/dev/disk/by-path')
                # find major number and minor number to device file
                stat = File.stat(sddev)
                f.puts "lxc.cgroup.devices.allow = b #{stat.rdev_major}:#{stat.rdev_minor} rwm"
              end
            }
          end
        }

        config_path
      end

      def create_fstab(ctx)
        config_path = "#{ctx.inst_data_dir}/fstab"
        File.open(config_path, "w") { |f|
          f.puts "proc   #{ctx.inst_data_dir}/rootfs/proc proc nodev,noexec,nosuid 0 0"
          f.puts "devpts #{ctx.inst_data_dir}/rootfs/dev/pts devpts defaults 0 0"
          f.puts "sysfs  #{ctx.inst_data_dir}/rootfs/sys sysfs defaults 0 0"
        }
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
