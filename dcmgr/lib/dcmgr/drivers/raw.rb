# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class Raw < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def create_volume(ctx, snap_file = nil)
        @volume_id   = ctx.volume_id
        @volume      = ctx.volume
        @snapshot    = ctx.snapshot

        logger.info("creating new volume: id:#{@volume_id} path:#{vol_path}.")
        logger.debug("volume: #{@volume.inspect}.")

        if @snapshot
          # sh("/bin/mkdir -p #{vol_path}") unless File.directory?(vol_path)
          cp_sparse(snap_file, vol_path)
          if $?.exitstatus != 0
            raise "failed copy snapshot: #{snap_file}"
          end
        else
          unless File.exist?(vol_path)
            logger.info("creating parent filesystem(size:#{@volume[:size]}): #{vol_path}")

            sh("/bin/mkdir -p #{File.dirname(vol_path)}") unless File.directory?(File.dirname(vol_path))
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

      def create_snapshot(ctx, snap_file)
        @volume      = ctx.volume

        logger.info("creating new snapshot: #{snap_file}")
        cp_sparse(vol_path, snap_file)
        if $?.exitstatus != 0
          raise "failed snapshot file : #{snap_file}"
        end
        du_hs(snap_file)

        logger.info("created new snapshot: #{snap_file}")
      end

      private
      def vol_path
        vol_base_path = @volume[:storage_node][:export_path]
        vol_account_path = "#{vol_base_path}/#{@volume[:account_id]}"
        "#{vol_account_path}/#{@volume[:uuid]}"
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
