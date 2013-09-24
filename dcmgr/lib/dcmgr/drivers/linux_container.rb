# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LinuxContainer < LinuxHypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::Cgroup::CgroupContextProvider
      include Dcmgr::Helpers::BlockDeviceHelper

      class Policy < HypervisorPolicy
        def validate_volume_model(volume)
          if !volume.guest_device_name.nil? && volume.guest_device_name !~ /^\//
            raise ValidataionError, "InvalidParameter: guest_device_name #{volume.guest_device_name}"
          end
        end

        def on_associate_volume(instance, volume)
          if instance.boot_volume_id == volume.canonical_uuid && volume.guest_device_name.nil?
            # helps only when root mount point is unset.
            volume.guest_device_name = '/'
          end
        end
      end

      def self.policy
        Policy.new
      end
      
      module SkipCheckHelper
        def self.stamp_path(instance_uuid)
          File.expand_path("#{instance_uuid}/skip_check.stamp", Dcmgr.conf.vm_data_dir)
        end

        def self.skip_check?(instance_uuid)
          if File.exists?(stamp_path(instance_uuid))
            s = File.stat(stamp_path(instance_uuid))
            return (Time.now - s.mtime) < 60.to_f
          end
          false
        end

        def self.skip_check(instance_uuid, &blk)
          File.open(stamp_path(instance_uuid), 'w')
          blk.call
        ensure
          File.unlink(stamp_path(instance_uuid)) rescue nil
        end
      end
      
      protected
      def check_cgroup_mount
        File.readlines('/proc/mounts').any? {|l| l.split(/\s+/)[2] == 'cgroup' }
      end

      def umount_root_image(ctx, mount_path)
        case ctx.inst[:image][:file_format]
        when "raw"
          # umount vm image directory
          raise "root mount point does not exist #{mount_path}" unless File.directory?(mount_path)
          sh("umount -l %s", [mount_path])
          if ctx.inst[:image][:root_device]
            detach_loop(ctx.os_devpath)
          end
          ctx.logger.debug("unmounted root mount directory #{mount_path}")
        end
      end
      
      def mount_root_image(ctx, mount_path)
        # check mount directory
        raise "Mount point for root image does not exist: #{mount_path}" unless File.directory?(mount_path)
        image = ctx.inst[:image]
        case image[:file_format]
        when "tgz"
          raise "TGZ is not supported yet"
        when "raw"
          # Raw image has two cases:
          #  1. plain raw image
          #  2. partition table.
          unless image[:root_device].nil?
            # creating loop devices
            mapdevs = sh("kpartx -av %s | egrep -v '^(gpt|dos):' | egrep ^add | awk '{print $3}'", [ctx.os_devpath])
            begin
              new_device_file = mapdevs[:stdout].split("\n").map {|mapdev| "/dev/mapper/#{mapdev}"}
              #
              # add map loop2p1 (253:2): 0 974609 linear
              # /dev/loop2 1
              # add map loop2p2 (253:3): 0 249856 linear
              # /dev/loop2 974848
              #
              # wait udev queue
              sh("udevadm settle")
              # find loopback device
              k, v = image[:root_device].split(":")
              case k
              when "uuid","label"
              else
                raise "unknown root device mapping key #{k}"
              end
              search_word = "#{k.upcase}=#{v}"
              device_file_list = sh("blkid -t %s |awk '{print $1}'", [search_word])
              #
              # /dev/mapper/loop0p1:
              # UUID="5eb668a7-176b-44ac-b0c0-ff808c191420"
              # TYPE="ext4"
              # /dev/mapper/loop2p1:
              # UUID="5eb668a7-176b-44ac-b0c0-ff808c191420"
              # TYPE="ext4"
              # /dev/mapper/ip-192.0.2.19:3260-iscsi-iqn.2010-09.jp.wakame:vol-lzt6zx5c-lun-1p1: UUID="148bc5df-3fc5-4e93-8a16-7328907cb1c0" TYPE="ext4"
              #
              device_file_list = device_file_list[:stdout].split(":\n")
              # root device
              root_device = new_device_file & device_file_list
              raise "root device does not exist #{image[:root_device]}" if root_device.empty?

              check_fs(root_device[0])
            rescue => e
              detach_loop(ctx.os_devpath)
              raise
            end
            sh("mount %s %s", [root_device[0], mount_path])

            # Write root partition identifier to instance
            # data dir for the failure recovery script
            File.open(File.expand_path('root_partition', ctx.inst_data_dir), 'w') {|f| f.puts(search_word) }
          else
            cmd = "mount %s %s"
            args = [ctx.os_devpath, mount_path]
            if image[:boot_dev_type] == 2
              cmd += " -o loop"
            end
            # mount vm image file
            sh(cmd, args)
          end
        end
        
      end
    end
  end
end
