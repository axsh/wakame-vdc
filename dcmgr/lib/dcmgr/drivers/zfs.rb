# -*- coding: utf-8 -*-
require 'fileutils'

module Dcmgr
  module Drivers
    class Zfs < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def create_volume(ctx, zsnap_file)
        @volume_id   = ctx.volume_id
        @volume      = ctx.volume
        @snapshot    = ctx.snapshot
        @destination = ctx.destination

        ### sta_handler :create_volume
        vol_path = "#{@volume[:storage_node][:export_path]}/#{@volume[:uuid]}"
        sh("/usr/sbin/zfs list %s", [File.dirname(vol_path)])
        if $?.exitstatus != 0
          # create parent filesystem
          sh("/usr/sbin/zfs create -p %s", [File.dirname(vol_path)])
          logger.info("create parent filesystem: #{File.dirname(vol_path)}")
        end

        if @snapshot
          # create volume from snapshot
          if File.exists?(zsnap_file)
            sh("/usr/sbin/zfs receive %s < %s", [vol_path, zsnap_file])
            if $?.exitstatus != 0
              raise "volume already exists: #{@volume_id}"
            end
          else
            raise "snapshot file isn't exists: #{zsnap_file}"
          end

          sh("/usr/sbin/zfs destroy %s@%s", [vol_path, @snapshot[:uuid]])
          if $?.exitstatus != 0
            raise "volume snapshot has not deleted: #{@volume_id}@#{@snapshot[:uuid]}"
          end
        else
          # create volume
          #sh("/usr/sbin/zfs create -p -V %s %s", ["#{@volume[:size]}", vol_path])
          # thin provisioning
          sh("/usr/sbin/zfs create -p -s -V %s %s", ["#{@volume[:size]}", vol_path])
          if $?.exitstatus != 0
            raise "volume already exists: #{@volume_id}"
          end
        end

        sh("/usr/sbin/zfs list %s", [vol_path])
        if $?.exitstatus != 0
          raise "volume has not be created: #{@volume_id}"
        end

        logger.info("created new volume: #{@volume_id}")
        ### sta_handler :create_volume
      end

      def delete_volume(ctx)
        @volume = ctx.volume
        sh("/usr/sbin/zfs destroy %s", ["#{@volume[:storage_node][:export_path]}/#{@volume[:uuid]}"])
      end

      def create_snapshot(ctx, zsnap_file)
        @snapshot_id = ctx.snapshot_id
        @destination = ctx.destination
        @snapshot    = ctx.snapshot
        @volume      = ctx.volume

        vol_path = "#{@volume[:storage_node][:export_path]}/#{@volume[:uuid]}"
        sh("/usr/sbin/zfs snapshot %s@%s", [vol_path, @snapshot[:uuid]])
        sh("/usr/sbin/zfs send %s@%s > %s", [vol_path, @snapshot[:uuid], zsnap_file])
        sh("/usr/sbin/zfs destroy %s@%s", [vol_path, @snapshot[:uuid]])
      end
    end
  end
end
