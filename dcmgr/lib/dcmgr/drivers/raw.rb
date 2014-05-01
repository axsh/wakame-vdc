# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class Raw < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::ByteUnit

      def_configuration do
        param :export_path
        param :local_backup_path
        param :snapshot_tmp_dir, :default=>'/var/tmp'

        def validate(errors)
          super
          
          unless File.directory?(@config[:export_path])
            errors << "Could not find the export_path: #{@config[:export_path]}"
          end
          
          unless File.directory?(@config[:local_backup_path])
            errors << "Could not find the local_backup_path: #{@config[:local_backup_path]}"
          end
          
          unless File.directory?(@config[:snapshot_tmp_dir])
            errors << "Could not find the snapshot_tmp_dir: #{@config[:snapshot_tmp_dir]}"
          end
        end
      end

      def create_volume(ctx, backup_key = nil)
        @volume_id   = ctx.volume_id
        @volume      = ctx.volume
        @backup_object    = ctx.backup_object

        if @backup_object
          logger.info("creating new volume: id:#{@volume_id} path:#{vol_path} from #{@backup_object[:uuid]}.")
          
        
          # sh("/bin/mkdir -p #{vol_path}") unless File.directory?(vol_path)
          cp_sparse(backup_real_path(backup_key), vol_path)
        else
          unless File.exist?(vol_path)
            logger.info("#{@volume_id}: creating blank volume (#{convert_byte(@volume[:size], MB)} MB): #{vol_path}")

            sh("/bin/dd if=/dev/zero of=#{vol_path} bs=1 count=0 seek=#{@volume[:size]}")
            du_hs(vol_path)

            logger.info("#{@volume_id}: Finish to create blank volume (#{convert_byte(@volume[:size], MB)} MB): #{vol_path}")
          else
            raise "volume already exists: #{@volume_id}"
          end
        end
      end

      def delete_volume(ctx)
        @volume = ctx.volume
        sh("/bin/rm %s", [vol_path]) if File.exists?(vol_path)
      end

      def create_snapshot(ctx)
        @volume = ctx.volume

        cp_sparse(vol_path, snapshot_path(ctx))
        du_hs(snapshot_path(ctx))
      end

      def delete_snapshot(ctx)
        File.unlink(snapshot_path(ctx)) rescue nil
      end

      def snapshot_path(ctx)
        File.expand_path("#{ctx.volume[:uuid]}.tmp", driver_configuration.snapshot_tmp_dir)
      end

      include BackingStore::ProvideBackupVolume

      def backup_volume(ctx)
        @volume = ctx.volume
        cp_sparse(vol_path, backup_real_path(backup_object_key_created(ctx)))
      end

      def delete_backup(ctx)
        File.unlink(backup_real_path(backup_object_key_created(ctx))) rescue nil
      end

      # @return String path to the backup object key by backup_volume().
      #
      # backup_volume(ctx)
      # puts backup_object_key_created(ctx)
      def backup_object_key_created(ctx)
        ctx.backup_object_id
      end

      private
      def vol_path
        case @volume[:volume_type]
        when 'Dcmgr::Models::LocalVolume'
          File.join(driver_configuration.export_path, @volume[:volume_device][:path])
        when 'Dcmgr::Models::NfsVolume'
          File.join(driver_configuration.export_path, @volume[:volume_device][:path])
        else
          raise "Unsupported volume type: #{@volume[:volume_type]}"
        end
      end

      def backup_real_path(backup_key)
        File.join(driver_configuration.local_backup_path, backup_key)
      end

      def cp_sparse(src, dst)
        sh("/bin/cp -p --sparse=always %s %s",[src, dst])
      end

      def du_hs(path)
        sh("du -hs %s", [path])
        sh("du -hs --apparent-size %s", [path])
      end

    end
  end
end
