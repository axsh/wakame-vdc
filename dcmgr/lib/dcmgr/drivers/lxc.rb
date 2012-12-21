# -*- coding: utf-8 -*-

require 'erb'

module Dcmgr
  module Drivers
    class Lxc < LinuxContainer
      include Dcmgr::Logger

      template_base_dir 'lxc'
      
      def_configuration

      # Decorator pattern class of Rpc::HvaHandler::HvaContext.
      class LxcContext
        def initialize(root_ctx)
          raise ArgumentError unless root_ctx.is_a?(Rpc::HvaContext)
          @subject = root_ctx
        end

        def lxc_conf_path
          File.expand_path('lxc.conf', @subject.inst_data_dir)
        end

        def root_mount_path
          File.expand_path('rootfs', @subject.inst_data_dir)
        end

        def metadata_drive_mount_path
          File.expand_path('rootfs/metadata', @subject.inst_data_dir)
        end

        private
        def method_missing(meth, *args)
          @subject.send(meth, *args)
        end
      end

      before do
        @args = @args.map {|i|  i.is_a?(Rpc::HvaContext) ? LxcContext.new(i) : i; }
        # First arugment is expected a HvaContext.
        @hc = @args.first
      end
      
      def initialize
        @lxc_version = `lxc-version`.chomp.split(': ').last
        logger.info("lxc-version: #{@lxc_version}")

        unless check_cgroup_mount
          raise "cgroup filesystem is not mounted."
        end
      end
      
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

        generate_config(ctx)
        sh("lxc-create -f %s -n %s", [ctx.lxc_conf_path, ctx.inst[:uuid]])

        poweron_instance(ctx)
      end

      def terminate_instance(ctx)
        poweroff_instance(ctx)
        shell.run("lxc-destroy -n #{ctx.inst_id}")
      end

      def reboot_instance(ctx)
        sh("lxc-stop -n #{ctx.inst[:uuid]}")
        sh("lxc-wait -n %s -s STOPPED", [ctx.inst_id])
        sh("lxc-start -n %s -d -c %s/console.log", [ctx.inst[:uuid], ctx.inst_data_dir])
      end

      def poweron_instance(ctx)
        # check mount point
        Dir.mkdir(ctx.root_mount_path) unless File.directory?(ctx.root_mount_path)
        mount_root_image(ctx, ctx.root_mount_path)

        # metadata drive
        Dir.mkdir(ctx.metadata_drive_mount_path) unless File.directory?(ctx.metadata_drive_mount_path)
        mount_metadata_drive(ctx, ctx.metadata_drive_mount_path)

        sh("lxc-start -d -n %s", [ctx.inst[:uuid], ctx.inst_data_dir])

        tryagain do
          begin
            check_instance(ctx.inst[:uuid])
            true
          rescue
            sleep 5
            false
          end
        end
      end

      def poweroff_instance(ctx)
        shell.run("lxc-stop -n #{ctx.inst_id}")
        shell.run("lxc-wait -n %s -s STOPPED", [ctx.inst_id])
        umount_metadata_drive(ctx, ctx.metadata_drive_mount_path)
        umount_root_image(ctx, ctx.root_mount_path)
      end
      
      def attach_volume_to_guest(ctx)
        sddev = File.expand_path(File.readlink(ctx.os_devpath), '/dev/disk/by-path')

        # find major number and minor number to device file
        stat = File.stat(sddev)
        devnum = [stat.rdev_major,stat.rdev_minor].join(':')

        sh("echo \"b #{devnum} rwm\" > /cgroup/#{ctx.inst_id}/devices.allow")
        logger.debug("Makinging new block device: #{ctx.inst_data_dir}/rootfs#{sddev}")
        sh("mknod #{ctx.inst_data_dir}/rootfs#{sddev} -m 660 b #{stat.rdev_major} #{stat.rdev_minor}")

        File.open(ctx.lxc_conf_path, 'a+') { |f|
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

        config_body = File.open(ctx.lxc_conf_path, 'r') { |f|
          f.readlines.select {|line| line != "lxc.cgroup.devices.allow = b #{devnum} rwm\n" }
        }
        File.open(ctx.lxc_conf_path, 'w') { |f|
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
      def generate_config(ctx)
        vifs = ctx.inst[:vif]

        render_template('lxc.conf', ctx.lxc_conf_path, binding)
      end
      
      Task::Tasklet.register(self.new)
    end
  end
end
