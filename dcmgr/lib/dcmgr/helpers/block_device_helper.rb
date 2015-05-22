# -*- coding: utf-8 -*-

module Dcmgr
  module Helpers
    module BlockDeviceHelper

      def mount_metadata_drive(ctx, mount_path, options = "-o ro")
        raise "Mount point for metadata image does not exist: #{mount_path}" unless File.directory?(mount_path)
        raise "Metadata image file does not exist #{ctx.metadata_img_path}" unless File.exists?(ctx.metadata_img_path)
        # mount metadata drive
        ve_metadata_path = mount_path
        res = sh("kpartx -av %s", [ctx.metadata_img_path])
        begin
          if res[:stdout] =~ /^add map (\w+) /
            lodev="/dev/mapper/#{$1}"
          else
            raise "Unexpected result from kpartx: #{res[:stdout]}"
          end
          sh("udevadm settle")

          # save the loop device name for the metadata drive.
          File.open(File.expand_path('metadata.lodev', ctx.inst_data_dir), 'w') {|f| f.puts(lodev) }
          check_fs(lodev)
        rescue => e
          detach_loop(ctx.metadata_img_path)
          raise
        end
        sh("mount #{options} %s %s", [lodev, ve_metadata_path])
      end

      def umount_metadata_drive(ctx, mount_path)
        # umount metadata drive
        #
        # *** Don't use "-l" option. ***
        # If "-l" option is added, umount command will get following messages.
        # > device-mapper: remove ioctl failed: Device or resource busy
        # > ioctl: LOOP_CLR_FD: Device or resource busy
        #
        sh("umount %s", [mount_path])
        detach_loop(ctx.metadata_img_path)
        ctx.logger.info("Umounted metadata directory #{mount_path}")
      end


      def check_fs(device)
        # Displays the problem in the stdout file system without fixing it.
        sh("fsck -n -M -v %s", [device])
      end

      # Find first matching loop device path from the result of "losetup -a"
      def find_loopdev(path)
        stat = File.stat(path)
        `losetup -a`.split(/\n/).each {|i|
          # /dev/loop0: [0f11]:1179651 (/home/katsuo/dev/wakame-vdc/tmp/instances/i-5....)
          if i =~ %r{^(/dev/loop\d+): \[([0-9a-f]+)\]:(\d+) } && $2.hex == stat.dev && $3.to_i == stat.ino
            return $1
          end
        }
        nil
      end

      # "kpartx -d" gets failed occasionally. so we use "dmsetup" and
      # "losetup -d" respectively since they do almost same steps as
      # what is done in "kpartx -d".
      # the difference is that it waits udev event before detach loop
      # device. this is very critical step and the root cause for
      # irregular failure of "kpartx -d".
      def detach_loop(imgpath)
        loopdev = find_loopdev(imgpath)
        raise "Failed to find loop device from: #{imgpath}" if loopdev.nil?

        Dir.glob("/dev/mapper/" + File.basename(loopdev) + "p*").each { |part_dev_path|
          r = shell.run("dmsetup info %s", [part_dev_path])
          if r.success? && r.out.split(/\n/).any? {|i| i =~ /^State:\s+ACTIVE/}
            shell.run("dmsetup remove %s", [part_dev_path])
            logger.info("Detached partition from devmapper: #{part_dev_path}")
          end
        }
        # Is "dmsetup wait" better here?
        shell.run("udevadm settle")

        if File.exist?(loopdev)
          shell.run("losetup -d %s", [loopdev])
          logger.info("Detached from loop device: #{loopdev}")
        end
      end

    end
  end
end
