# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LinuxContainer < LinuxHypervisor
      include Dcmgr::Logger
      include Dcmgr::Helpers::Cgroup::CgroupContextProvider

      protected
      def check_cgroup_mount
        File.readlines('/proc/mounts').any? {|l| l.split(/\s+/)[2] == 'cgroup' }
      end

      def mount_metadata_drive(ctx, mount_path)
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
        sh("mount -o ro %s %s", [lodev, ve_metadata_path])
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
              detach_loop(hc.os_devpath)
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
