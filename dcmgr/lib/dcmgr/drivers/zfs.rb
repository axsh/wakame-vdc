# -*- coding: utf-8 -*-
require 'fileutils'

module Dcmgr
  module Drivers
    class Zfs < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def create_volume(ctx)
        @volume_id   = ctx.volume_id
        @volume      = ctx.volume
        @snapshot    = ctx.snapshot
        @destination = ctx.destination

        ### sta_handler :create_volume
        vol_path = "#{@volume[:storage_pool][:export_path]}/#{@volume[:uuid]}"
        sh("/usr/sbin/zfs list %s", [File.dirname(vol_path)])
        if $?.exitstatus != 0
          # create parent filesystem
          sh("/usr/sbin/zfs create -p %s", [File.dirname(vol_path)])
          logger.info("create parent filesystem: #{File.dirname(vol_path)}")
        end

        if @snapshot
          zsnap_dir = "#{@volume[:storage_pool][:snapshot_base_path]}/#{@snapshot[:account_id]}/"
          zsnap_filename = "#{@snapshot[:uuid]}.zsnap"
          zsnap_file = File.join(zsnap_dir, zsnap_filename)

          unless File.exists?(zsnap_file)
            if Dcmgr::StorageService.has_driver?(@destination[:driver])
              begin
                storage = Dcmgr::StorageService.new(@destination[:driver], @destination[:access_key], @destination[:secret_key])
                snapshot_file = "#{@destination[:path]}#{@destination[:filename]}"
                bucket = storage.bucket(@destination[:bucket])
                bucket.download(snapshot_file, zsnap_filename, zsnap_dir)
                logger.info("download to #{@destination[:driver]}: #{snapshot_file}")
              rescue => e
                logger.error(e.message)
                raise "snapshot not downloaded" if $?.exitstatus != 0
              end
            end
          end

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

          sh("/usr/sbin/zfs list %s", [vol_path])
          if $?.exitstatus != 0
            raise "volume has not be created: #{@volume_id}"
          end

          FileUtils.rm("#{@volume[:storage_pool][:snapshot_base_path]}/#{@snapshot[:account_id]}/#{@snapshot[:uuid]}.zsnap")
          logger.info("delete file: " + File.join(zsnap_dir, zsnap_file))

          if $?.exitstatus != 0
            raise "snapshot file cna't deleted"
          end
        else
          # create volume
          #sh("/usr/sbin/zfs create -p -V %s %s", ["#{@volume[:size]}m", vol_path])
          # thin provisioning
          sh("/usr/sbin/zfs create -p -s -V %s %s", ["#{@volume[:size]}m", vol_path])
          if $?.exitstatus != 0
            raise "volume already exists: #{@volume_id}"
          end
          sh("/usr/sbin/zfs list %s", [vol_path])
          if $?.exitstatus != 0
            raise "volume has not be created: #{@volume_id}"
          end
        end

        logger.info("created new volume: #{@volume_id}")
        ### sta_handler :create_volume
      end

      def delete_volume(ctx)
        @volume = ctx.volume
        sh("/usr/sbin/zfs destroy %s", ["#{@volume[:storage_pool][:export_path]}/#{@volume[:uuid]}"])
      end

      def create_snapshot(ctx)
        @snapshot_id = ctx.snapshot_id
        @destination = ctx.destination
        @snapshot    = ctx.snapshot
        @volume      = ctx.volume

        vol_path = "#{@volume[:storage_pool][:export_path]}/#{@volume[:uuid]}"
        snap_dir = "#{@volume[:storage_pool][:snapshot_base_path]}/#{@snapshot[:account_id]}"
        unless File.exist?(snap_dir)
          # create a directory to save snapshot
          FileUtils.mkdir(snap_dir)
          logger.info("create a directory: #{snap_dir}")
        end
        sh("/usr/sbin/zfs snapshot %s@%s", [vol_path, @snapshot[:uuid]])
        zsnap_file = "#{snap_dir}/#{@snapshot[:uuid]}.zsnap"
        sh("/usr/sbin/zfs send %s@%s > %s", [vol_path, @snapshot[:uuid], zsnap_file])
        sh("/usr/sbin/zfs destroy %s@%s", [vol_path, @snapshot[:uuid]])

        if Dcmgr::StorageService.has_driver?(@destination[:driver])
          begin
            storage = Dcmgr::StorageService.new(@destination[:driver], @destination[:access_key], @destination[:secret_key])
            snapshot_file = "#{@destination[:path]}#{destination[:filename]}"
            bucket = storage.bucket(@destination[:bucket])
            bucket.upload(snapshot_file, "#{zsnap_file}")
            logger.info("upload to #{@destination[:driver]}: #{snapshot_file}")
          rescue => e
            logger.error(e.message)
            raise "snapshot has not be uploaded" if $?.exitstatus != 0
          ensure
            FileUtils.rm("#{@volume[:storage_pool][:snapshot_base_path]}/#{@snapshot[:account_id]}/#{@snapshot[:uuid]}.zsnap")
          end
        end
      end

      def delete_snapshot(ctx)
        @snapshot_id = ctx.snapshot_id
        @destination = ctx.destination
        @snapshot    = ctx.snapshot
        @volume      = ctx.volume

        if Dcmgr::StorageService.has_driver?(@destination[:driver])
          begin
            storage = Dcmgr::StorageService.new(@destination[:driver], @destination[:access_key], @destination[:secret_key])
            snapshot_file = "#{@destination[:path]}#{@destination[:filename]}"
            bucket = storage.bucket(@destination[:bucket])
            bucket.delete(snapshot_file)
            logger.info("delete sanpshot file from #{@destination[:driver]}: #{snapshot_file}")
          rescue => e
            logger.error(e.message)
            raise "snapshot has not be deleted" if $?.exitstatus != 0
          end
        else
          FileUtils.rm("#{@volume[:storage_pool][:snapshot_base_path]}/#{@snapshot[:account_id]}/#{@snapshot[:uuid]}.zsnap")
          raise "snapshot has not be deleted" if $?.exitstatus != 0
        end
      end
    end
  end
end
