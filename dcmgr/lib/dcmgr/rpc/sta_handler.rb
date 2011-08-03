# -*- coding: utf-8 -*-
require 'isono'
require 'net/telnet'
require 'fileutils'

module Dcmgr
  module Rpc

    class StaHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      job :create_volume do
        volume_id = request.args[0]
        dest = Dcmgr::StorageService.repository(request.args[1])
        data = rpc.request('sta-collector', 'get_volume', volume_id)
        raise "Invalid volume state: #{data[:state]}" unless data[:state].to_s == 'registering'

        unless data[:snapshot_id].nil?
          sdata = rpc.request('sta-collector', 'get_snapshot', data[:snapshot_id])
          raise "Invalid snapshot state: #{sdata[:state]}" unless sdata[:state].to_s == 'available'
        end
        logger.info("creating new volume #{volume_id}")

        rpc.request('sta-collector', 'update_volume', volume_id, {:state=>:creating, :export_path=>data[:uuid]})

        vol_path = "#{data[:storage_pool][:export_path]}/#{data[:uuid]}"
        sh("/usr/sbin/zfs list %s > /dev/null 2>&1", [File.dirname(vol_path)])
        if $?.exitstatus != 0
          # create parent filesystem
          sh("/usr/sbin/zfs create -p %s", [File.dirname(vol_path)])
          logger.info("create parent filesystem: #{File.dirname(vol_path)}")
        end

        if sdata
          zsnap_dir = "#{data[:storage_pool][:snapshot_base_path]}/#{sdata[:account_id]}/"
          zsnap_filename = "#{sdata[:uuid]}.zsnap"
          zsnap_file = File.join(zsnap_dir, zsnap_filename)

          unless File.exists?(zsnap_file)
            if Dcmgr::StorageService.has_driver?(dest[:driver])
              begin
                storage = Dcmgr::StorageService.new(dest[:driver], dest[:access_key], dest[:secret_key])
                snapshot_file = "#{dest[:path]}#{dest[:filename]}"
                bucket = storage.bucket(dest[:bucket])
                bucket.download(snapshot_file, zsnap_filename, zsnap_dir)
                logger.info("download to #{dest[:driver]}: #{snapshot_file}")
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
              raise "volume already exists: #{volume_id}"
            end
          else
            raise "snapshot file isn't exists: #{zsnap_file}"
          end

          sh("/usr/sbin/zfs destroy %s@%s", [vol_path, sdata[:uuid]])
          if $?.exitstatus != 0
            raise "volume snapshot has not deleted: #{volume_id}@#{sdata[:uuid]}"
          end

          sh("/usr/sbin/zfs list %s", [vol_path])
          if $?.exitstatus != 0
            raise "volume has not be created: #{volume_id}"
          end

        else
          # create volume
          sh("/usr/sbin/zfs create -p -V %s %s", ["#{data[:size]}m", vol_path])
          if $?.exitstatus != 0
            raise "volume already exists: #{volume_id}"
          end
          sh("/usr/sbin/zfs list %s", [vol_path])
          if $?.exitstatus != 0
            raise "volume has not be created: #{volume_id}"
          end
        end

        logger.info("created new volume: #{volume_id}")

        sh("/usr/sbin/zfs shareiscsi=on %s/%s", [data[:storage_pool][:export_path], data[:uuid]])
        if $?.exitstatus != 0
          raise "failed iscsi target request: #{volume_id}"
        end
        il = sh("iscsitadm list target -v %s", ["#{data[:storage_pool][:export_path]}/#{data[:uuid]}"])
        if $?.exitstatus != 0
          raise "iscsi target has not be created #{volume_id}"
        end
        il = il[:stdout].downcase.split("\n").select {|row| row.strip!}
        # :transport_information => {:iqn => "iqn.1986-03.com.sun:02:787bca42-9639-44e4-f115-f5b06ed31817", :lun => 0}
        opt = {:iqn => il[0].split(": ").last, :lun=>il[6].split(": ").last.to_i}

        rpc.request('sta-collector', 'update_volume', volume_id, {:state=>:available, :transport_information=>opt})
        logger.info("registered iscsi target: #{volume_id}")
      end

      job :delete_volume do
        volume_id = request.args[0]
        data = rpc.request('sta-collector', 'get_volume', volume_id)
        logger.info("#{volume_id}: start deleting volume.")
        errcount = 0
        if data[:state].to_s == 'deleted'
          raise "#{volume_id}: Invalid volume state: deleted"
        end
        if data[:state].to_s != 'deregistering'
          logger.warn("#{volume_id}: Unexpected volume state but try again: #{data[:state]}")
        end

        # deregisterd iscsi target
        begin
          sh("/usr/sbin/zfs shareiscsi=off %s", ["#{data[:storage_pool][:export_path]}/#{data[:uuid]}"])
        rescue => e
          logger.error("#{volume_id}: Failed to delete ISCSI target entry.")
          errcount += 1
        end

        rpc.request('sta-collector', 'update_volume', volume_id, {:state=>:deleting})

        # delete volume
        begin
          sh("/usr/sbin/zfs destroy %s", ["#{data[:storage_pool][:export_path]}/#{data[:uuid]}"])
        rescue => e
          logger.error("#{volume_id}: Failed to delete zfs volume: #{data[:storage_pool][:export_path]}/#{data[:uuid]}")
          errcount += 1
        end

        rpc.request('sta-collector', 'update_volume', volume_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        if errcount > 0
          logger.info("#{volume_id}: Encountered one or more errors during deleting.")
        else
          logger.info("#{volume_id}: Deleted volume successfully.")
        end
      end

      job :create_snapshot do
        snapshot_id = request.args[0]
        dest = Dcmgr::StorageService.repository(request.args[1])
        sdata = rpc.request('sta-collector', 'get_snapshot', snapshot_id) unless snapshot_id.nil?
        data = rpc.request('sta-collector', 'get_volume', sdata[:origin_volume_id])
        logger.info("create new snapshot: #{snapshot_id}")
        raise "Invalid volume state: #{data[:state]}" unless data[:state].to_s == 'available' || data[:state].to_s == 'attached'

        vol_path = "#{data[:storage_pool][:export_path]}/#{data[:uuid]}"
        snap_dir = "#{data[:storage_pool][:snapshot_base_path]}/#{sdata[:account_id]}"
        unless File.exist?(snap_dir)
          # create a directory to save snapshot
          `mkdir -p #{snap_dir}`
          logger.info("create a directory: #{snap_dir}")
        end
        sh("/usr/sbin/zfs snapshot %s@%s", [vol_path, sdata[:uuid]])
        zsnap_file = "#{snap_dir}/#{sdata[:uuid]}.zsnap"
        sh("/usr/sbin/zfs send %s@%s > %s", [vol_path, sdata[:uuid], zsnap_file])
        sh("/usr/sbin/zfs destroy %s@%s", [vol_path, sdata[:uuid]])

        if Dcmgr::StorageService.has_driver?(dest[:driver])
          begin
            storage = Dcmgr::StorageService.new(dest[:driver], dest[:access_key], dest[:secret_key])
            snapshot_file = "#{dest[:path]}#{dest[:filename]}"
            bucket = storage.bucket(dest[:bucket])
            bucket.upload(snapshot_file, "#{zsnap_file}")
            logger.info("upload to #{dest[:driver]}: #{snapshot_file}")
          rescue => e
            logger.error(e.message)
            raise "snapshot has not be uploaded" if $?.exitstatus != 0
          ensure
            sh("rm -rf %s", ["#{data[:storage_pool][:snapshot_base_path]}/#{sdata[:account_id]}/#{sdata[:uuid]}.zsnap"])
          end
        end

        rpc.request('sta-collector', 'update_snapshot', snapshot_id, {:state=>:available})
        logger.info("created new snapshot: #{snapshot_id}")
      end

      job :delete_snapshot do
        snapshot_id = request.args[0]
        dest = Dcmgr::StorageService.repository(request.args[1])
        sdata = rpc.request('sta-collector', 'get_snapshot', snapshot_id)
        data = rpc.request('sta-collector', 'get_volume', sdata[:origin_volume_id])
        logger.info("deleting snapshot: #{snapshot_id}")
        raise "Invalid snapshot state: #{sdata[:state]}" unless sdata[:state].to_s == 'deleting'

        if Dcmgr::StorageService.has_driver?(dest[:driver])
          begin
            storage = Dcmgr::StorageService.new(dest[:driver], dest[:access_key], dest[:secret_key])
            snapshot_file = "#{dest[:path]}#{dest[:filename]}"
            bucket = storage.bucket(dest[:bucket])
            bucket.delete(snapshot_file)
            logger.info("delete sanpshot file from #{dest[:driver]}: #{snapshot_file}")
          rescue => e
            logger.error(e.message)
            raise "snapshot has not be deleted" if $?.exitstatus != 0
          end
        else
          sh("rm -rf %s", ["#{data[:storage_pool][:snapshot_base_path]}/#{sdata[:account_id]}/#{sdata[:uuid]}.zsnap"])
          raise "snapshot has not be deleted" if $?.exitstatus != 0
        end

        rpc.request('sta-collector', 'update_snapshot', snapshot_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        logger.info("deleted snapshot: #{snapshot_id}")
      end

      def rpc
        @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
      end

      def jobreq
        @jobreq ||= Isono::NodeModules::JobChannel.new(@node)
      end

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end

  end
end
