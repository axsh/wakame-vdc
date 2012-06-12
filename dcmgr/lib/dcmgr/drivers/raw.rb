# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class Raw < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def create_volume(ctx, snap_file = nil)
        @volume_id   = ctx.volume_id
        @volume      = ctx.volume
        @backup_object    = ctx.backup_object

        logger.info("creating new volume: id:#{@volume_id} path:#{vol_path}.")
        logger.debug("volume: #{@volume.inspect}.")

        if @backup_object
          # sh("/bin/mkdir -p #{vol_path}") unless File.directory?(vol_path)
          cp_sparse(snap_file, vol_path)
        else
          unless File.exist?(vol_path)
            logger.info("creating parent filesystem(size:#{@volume[:size]}): #{vol_path}")

            sh("/bin/dd if=/dev/zero of=#{vol_path} bs=1 count=0 seek=#{@volume[:size] * 1024 * 1024}")
            du_hs(vol_path)

            logger.info("create parent filesystem(size:#{@volume[:size]}): #{vol_path}")
          else
            raise "volume already exists: #{@volume_id}"
          end
        end

        logger.info("created new volume: #{@volume_id}")
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
        File.expand_path("#{ctx.volume[:uuid]}.tmp", Dcmgr.conf.raw_backing_store.snapshot_tmp_dir)
      end

      private
      def vol_path
        vol_base_path = @volume[:storage_node][:export_path]
        raise "Volume base path does not exist: #{vol_base_path}" unless File.directory?(vol_base_path)
        "#{vol_base_path}/#{@volume[:uuid]}"
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
