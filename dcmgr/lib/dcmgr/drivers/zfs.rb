# -*- coding: utf-8 -*-
require 'fileutils'

module Dcmgr
  module Drivers
    class Zfs < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def_configuration do
        param :zfs_path, :default=>'/sbin/zfs'

        # Requires to set in sta.conf.
        param :zpool_base_path

        param :snapshot_export_base, :default=>nil

        def snapshot_export_path
          # snapshot_export_base can have nil.
          @config[:snapshot_export_base].nil? ?
             @config[:zpool_base_path] : File.join(@config[:zpool_base_path], @config[:snapshot_export_base].to_s)
        end

        def validate(errors)
          super
          
          if config[:zpool_base_path].nil?
            errors.add("zpool_base_path is unset.")
          elsif config[:zpool_base_path] =~ %r{^/}
            errors.add("zpool_base_path can not start with '/'.")
          else
            system("#{config[:zfs_path]} list #{config[:zpool_base_path]} > /dev/null")
            if $?.exitstatus != 0
              errors.add("zpool_base_path does not exist: #{config[:zpool_base_path]}")
            else
              system("#{config[:zfs_path]} list #{self.snapshot_export_path()} > /dev/null")
              if $?.exitstatus != 0
                errors.add("snapshot_export_base does not exist or is invalid: #{self.snapshot_export_path()}")
              end
            end
          end
        end
      end

      module BackupAsSnapshot
        include Drivers::BackingStore::ProvideBackupVolume

        def create_volume(ctx, snap_path=nil)
          @volume      = ctx.volume
          if snap_path
            `#{driver_configuration.zfs_path} list '#{zsnap_path(snap_path)}'`
            if $?.exitstatus != 0
              raise "snapshot does not exist: #{ctx.volume_id}: #{zsnap_path(snap_path)}"
            end

            # create full copy volume from snapshot
            sh("#{driver_configuration.zfs_path} send %s | #{driver_configuration.zfs_path} recv %s", [zsnap_path(snap_path), volume_path()])
            
            zfs("rollback -r %s@%s", [volume_path(), snap_path.split('@').last])
            zfs("destroy %s@%s", [volume_path(), snap_path.split('@').last])
          else
            # create blank volume
            #sh("/usr/sbin/zfs create -p -V %s %s", ["#{@volume[:size]}", volume_path()])
            # thin provisioning
            zfs("create -p -s -V %s %s", ["#{@volume[:size]}", volume_path()])
          end

          sh("udevadm settle")
          logger.info("created new volume #{ctx.volume_id} at #{volume_path()}")
        end

        def delete_volume(ctx)
          @volume = ctx.volume
          # mark as logical remove.
          zfs("set wakame:deleted=true %s", [volume_path()])
          begin
            # This may fail.
            zfs("destroy %s", [volume_path()])
          rescue => e
            logger.warn("Skip to immediate destroy #{ctx.volume_id} at #{volume_path()}. child snapshots/clones still exist.")
          end
        end

        def backup_object_key_created(ctx)
          "#{ctx.volume_id}@#{ctx.backup_object_id}"
        end

        def backup_volume(ctx)
          @volume = ctx.volume
          zfs("snapshot %s@%s", [volume_path(), ctx.backup_object_id])
          # create clone of the snapshot to expose the raw dev under /dev/zvol/<zsnap_clone_path>/bo-xxxx
          zfs("clone -o readonly=on %s@%s %s", [volume_path(), ctx.backup_object_id, zsnap_clone_path(ctx.backup_object_id)])
        end

        # zfs snapshot can fail to remove if it has children or
        # dependants. it mainly marks deleted flag as user zfs
        # property then tries zfs destroy once.
        def delete_backup(ctx)
          zfs("set wakame:deleted=true %s", [zsnap_clone_path(ctx.backup_object_id)])
          begin
            # This may fail.
            zfs("destroy -r %s", [zsnap_clone_path(ctx.backup_object_id)])
          rescue => e
            logger.warn("Skip to immediate destroy snapshot #{ctx.backup_object_id} at #{zsnap_clone_path(ctx.backup_object_id)}. child snapshots/clones still exist.")
          end
        end

        private
        # Caluculate zfs snapshot path.
        # Due to zfs snapshot naming convention, it is difficult to
        # guess absolute path from backup object UUID only.
        #   zpool/vol-xxxx@bo-xxxx
        #
        
        def zsnap_path(snap_path)
          File.join(driver_configuration.zpool_base_path, snap_path)
        end
      end

      include BackupAsSnapshot
      
      end

      private
      def volume_path
        File.join(driver_configuration.zpool_base_path, @volume[:uuid])
      end

      def zfs(cmd, args=[])
        sh("#{driver_configuration.zfs_path} " + cmd, args)
      end
    end
  end
end
