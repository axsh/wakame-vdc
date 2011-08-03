# -*- coding: utf-8 -*-
require 'isono'

module Dcmgr
  module Rpc

    class StaTgtHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::StaTgtHelper
      
      job :create_volume do
        volume_id = request.args[0]
        dest = Dcmgr::StorageService.repository(request.args[1])
        data = rpc.request('sta-collector', 'get_volume', volume_id)
        raise "Invalid volume state: #{data[:state]}" unless data[:state].to_s == 'registering'
        
        unless data[:snapshot_id].nil?
          sdata = rpc.request('sta-collector', 'get_snapshot', data[:snapshot_id])
          raise "Invalid snapshot state: #{sdata[:state]}" unless sdata[:state].to_s == 'available'
        end
    
        rpc.request('sta-collector', 'update_volume', volume_id, { :state => :creating, :export_path => data[:uuid] })
            
        vol_base_path = data[:storage_pool][:export_path]
        vol_account_path = "#{vol_base_path}/#{data[:account_id]}"
        vol_path = "#{vol_account_path}/#{data[:uuid]}"
        unless File.exists? vol_account_path
          Dir.mkdir vol_account_path
          logger.info("create account directory: #{vol_account_path}")
        end
        
        if sdata
          snap_dir = "#{data[:storage_pool][:snapshot_base_path]}/#{sdata[:account_id]}/"
          snap_filename = "#{sdata[:uuid]}.snap"
          snap_file = File.join(snap_dir, snap_filename)
          unless File.exists?(snap_file)
            if Dcmgr::StorageService.has_driver?(dest[:driver])
              begin
                storage = Dcmgr::StorageService.new(dest[:driver], dest[:access_key], dest[:secret_key])
                snapshot_file = "#{dest[:path]}#{dest[:filename]}"
                bucket = storage.bucket(dest[:bucket])
                bucket.download(snapshot_file, snap_filename, snap_dir)
                logger.info("download to #{dest[:driver]}: #{snapshot_file}")
              rescue => e
                logger.error(e.message)
                raise "snapshot not downloaded" if $?.exitstatus != 0
              end
            end
          end
          sh("/bin/cp -p %s %s",[snap_file, vol_path])
          if $?.exitstatus != 0
            raise "failed copy snapshot: #{snap_file}"
          end
        else
          unless File.exist?(vol_path)
            sh("/bin/dd if=/dev/zero of=#{vol_path} bs=#{data[:size]} count=1000000")
            logger.info("create parent filesystem: #{vol_path}")
          else
            raise "volume already exists: #{volume_id}"
          end
        end
    
        iscsi = {}
        iscsi[:iqn] = "#{@node.manifest.config.iqn_prefix}:#{data[:account_id]}.#{data[:uuid]}"
        iscsi[:tid] = data[:id]
        iscsi[:lun] = 1
        iscsi[:backing_store] = vol_path
        iscsi[:initiator_address] = @node.manifest.config.initiator_address 
        
        register_target(iscsi[:tid], iscsi[:iqn])
        register_logicalunit(iscsi[:tid], iscsi[:lun], iscsi[:backing_store])
        bind_target(iscsi[:tid], iscsi[:initiator_address])
        
        opt = { :iqn => iscsi[:iqn], :lun => iscsi[:lun], :tid => iscsi[:tid], :backing_store => iscsi[:backing_store] }
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
          sh("/usr/sbin/tgt-admin --delete #{data[:transport_information][:iqn]}")
        rescue => e
          logger.error("#{volume_id}: Failed to delete ISCSI target entry.")
          errcount += 1
        end
        
        rpc.request('sta-collector', 'update_volume', volume_id, {:state=>:deleting})
        
        # delete volume
        begin
          vol_base_path = data[:storage_pool][:export_path]
          vol_account_path = "#{vol_base_path}/#{data[:account_id]}"
          vol_path = "#{vol_account_path}/#{data[:uuid]}"
          sh("/bin/rm %s", [vol_path])
        rescue => e
          logger.error("#{volume_id}: Failed to delete zfs volume: #{vol_path}")
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
        
        vol_base_path = data[:storage_pool][:export_path]
        vol_account_path = "#{vol_base_path}/#{data[:account_id]}"
        vol_path = "#{vol_account_path}/#{data[:uuid]}"
        snap_file = "#{snap_dir}/#{sdata[:uuid]}.snap"
        sh("/bin/cp -p %s %s",[vol_path, snap_file])
        
        if $?.exitstatus != 0
          raise "failed snapshot file : #{snap_file}"
        end 
    
        if Dcmgr::StorageService.has_driver?(dest[:driver])
          begin
            storage = Dcmgr::StorageService.new(dest[:driver], dest[:access_key], dest[:secret_key])
            snapshot_file = "#{dest[:path]}#{dest[:filename]}"
            bucket = storage.bucket(dest[:bucket])
            bucket.upload(snapshot_file, "#{snap_file}")
            logger.info("upload to #{dest[:driver]}: #{snapshot_file}")
          rescue => e
            logger.error(e.message)
            raise "snapshot has not be uploaded" if $?.exitstatus != 0
          ensure
            sh("rm -rf %s", ["#{data[:storage_pool][:snapshot_base_path]}/#{sdata[:account_id]}/#{sdata[:uuid]}.snap"])
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
          sh("rm -rf %s", ["#{data[:storage_pool][:snapshot_base_path]}/#{sdata[:account_id]}/#{sdata[:uuid]}.snap"])
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
