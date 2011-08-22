# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class Tgt < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      
      def create_volume(ctx, snap_file = nil)
        @volume_id   = ctx.volume_id
        @volume      = ctx.volume

        if @snapshot
          sh("/bin/cp -p %s %s",[snap_file, vol_path])
          if $?.exitstatus != 0
            raise "failed copy snapshot: #{snap_file}"
          end
        else
          unless File.exist?(vol_path)
            sh("/bin/dd if=/dev/zero of=#{vol_path} bs=#{@volume[:size]} count=1000000")
            logger.info("create parent filesystem: #{vol_path}")
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
        
        vol_base_path = @volume[:storage_pool][:export_path]
        vol_account_path = "#{vol_base_path}/#{@volume[:account_id]}"
        vol_path = "#{vol_account_path}/#{@volume[:uuid]}"
        
        sh("/bin/cp -p %s %s",[vol_path, snap_file])
        if $?.exitstatus != 0
          raise "failed snapshot file : #{snap_file}"
        end 
      end

      def vol_path
        vol_base_path = @volume[:storage_pool][:export_path]
        vol_account_path = "#{vol_base_path}/#{@volume[:account_id]}"
        "#{vol_account_path}/#{@volume[:uuid]}"
      end
    end
  end
end
