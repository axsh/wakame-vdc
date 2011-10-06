# -*- coding: utf-8 -*-
require 'isono'
require 'net/telnet'
require 'fileutils'

module Dcmgr
  module Rpc

    class StaHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper

      def select_backing_store
        backing_store = @node.manifest.config.backing_store 
        @backing_store = Dcmgr::Drivers::BackingStore.select_backing_store(backing_store)
      end

      def select_iscsi_target
        iscsi_target = @node.manifest.config.iscsi_target
        @iscsi_target = Dcmgr::Drivers::IscsiTarget.select_iscsi_target(iscsi_target, @node)
      end

      job :create_volume, proc {
        @volume_id = request.args[0]
        @destination = Dcmgr::StorageService.repository(request.args[1])
        @volume = rpc.request('sta-collector', 'get_volume', @volume_id)
        raise "Invalid volume state: #{@volume[:state]}" unless @volume[:state].to_s == 'pending'

        snapshot_file = nil 
        unless @volume[:snapshot_id].nil?
          @snapshot = rpc.request('sta-collector', 'get_snapshot', @volume[:snapshot_id])
          raise "Invalid snapshot state: #{@snapshot[:state]}" unless @snapshot[:state].to_s == 'available'
          snap_filename = @destination[:filename] 
          
          begin
            storage_service = Dcmgr::StorageService.new(@destination[:driver], {
              :account_id => @snapshot[:account_id],
              :access_key => @destination[:access_key], 
              :secret_key => @destination[:secret_key],
            })
            snapshot_storage = storage_service.snapshot_storage(@destination[:bucket], @destination[:path]) 
            snapshot_storage.download(snap_filename)
            snapshot_file = snapshot_storage.snapshot(snap_filename)
            logger.info("download to #{@destination[:driver]}: #{snap_filename}")
          rescue => e
            logger.error(e)
            raise "snapshot not downloaded"
          end
        end

        logger.info("creating new volume #{@volume_id}")

        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:creating, :export_path=>@volume[:uuid]})

        select_backing_store
        @backing_store.create_volume(StaContext.new(self), snapshot_file)
        
        unless @volume[:snapshot_id].nil?
          snapshot_storage.clear
        end

        select_iscsi_target
        opt = @iscsi_target.create(StaContext.new(self))
        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:available, :transport_information=>opt})
        logger.info("registered iscsi target: #{@volume_id}")
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        logger.error("Failed to run create_volume: #{@volume_id}")
      }

      job :delete_volume do
        @volume_id = request.args[0]
        @volume = rpc.request('sta-collector', 'get_volume', @volume_id)
        logger.info("#{@volume_id}: start deleting volume.")
        errcount = 0
        if @volume[:state].to_s == 'deleted'
          raise "#{@volume_id}: Invalid volume state: deleted"
        end
        if @volume[:state].to_s != 'deregistering'
          logger.warn("#{@volume_id}: Unexpected volume state but try destroy resource: #{@volume[:state]}")
        end

        # deregisterd iscsi target
        select_iscsi_target
        begin
          @iscsi_target.delete(StaContext.new(self))
        rescue => e
          logger.error("#{@volume_id}: Failed to delete ISCSI target entry.")
          errcount += 1
        end

        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:deleting})

        # delete volume
        select_backing_store
        begin
          @backing_store.delete_volume(StaContext.new(self))
        rescue => e
          logger.error("#{@volume_id}: Failed to delete zfs volume: #{@volume[:storage_node][:export_path]}/#{@volume[:uuid]}")
          errcount += 1
        end

        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        if errcount > 0
          logger.info("#{@volume_id}: Encountered one or more errors during deleting.")
        else
          logger.info("#{@volume_id}: Deleted volume successfully.")
        end
      end

      job :create_snapshot, proc {
        @snapshot_id = request.args[0]
        @destination = Dcmgr::StorageService.repository(request.args[1])
        @snapshot = rpc.request('sta-collector', 'get_snapshot', @snapshot_id) unless @snapshot_id.nil?
        @volume = rpc.request('sta-collector', 'get_volume', @snapshot[:origin_volume_id])

        logger.info("create new snapshot: #{@snapshot_id}")
        raise "Invalid volume state: #{@volume[:state]}" unless %w(available attached).member?(@volume[:state].to_s)
        
        begin 
          storage_service = Dcmgr::StorageService.new(@destination[:driver], {
            :account_id => @snapshot[:account_id],
            :access_key => @destination[:access_key], 
            :secret_key => @destination[:secret_key],
          })
          snapshot_storage = storage_service.snapshot_storage(@destination[:bucket], @destination[:path])
          select_backing_store
          
          snap_filename = @destination[:filename] 
          @backing_store.create_snapshot(StaContext.new(self), snapshot_storage.snapshot(snap_filename))
       
          snapshot_storage.upload(snap_filename)
          snapshot_storage.clear
          logger.info("upload to #{@destination[:driver]}: #{snap_filename}")
        rescue => e
          logger.error(e)
          raise "snapshot has not be uploaded"
        end
        
        rpc.request('sta-collector', 'update_snapshot', @snapshot_id, {:state=>:available})
        logger.info("created new snapshot: #{@snapshot_id}")
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_snapshot', @snapshot_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        logger.error("Failed to run create_snapshot: #{@snapshot_id}")
      }

      job :delete_snapshot do
        @snapshot_id = request.args[0]
        @destination = Dcmgr::StorageService.repository(request.args[1])
        @snapshot = rpc.request('sta-collector', 'get_snapshot', @snapshot_id)
        @volume = rpc.request('sta-collector', 'get_volume', @snapshot[:origin_volume_id])
        logger.info("deleting snapshot: #{@snapshot_id}")
        raise "Invalid snapshot state: #{@snapshot[:state]}" unless @snapshot[:state].to_s == 'deleting'
        begin 
          storage_service = Dcmgr::StorageService.new(@destination[:driver], {
            :account_id => @snapshot[:account_id],
            :access_key => @destination[:access_key], 
            :secret_key => @destination[:secret_key],
          })
          snapshot_storage = storage_service.snapshot_storage(@destination[:bucket], @destination[:path])
          snapshot_storage.delete(@destination[:filename])
        rescue => e
           logger.error(e)
           raise "snapshot has not be deleted"
        end
 
        rpc.request('sta-collector', 'update_snapshot', @snapshot_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        logger.info("deleted snapshot: #{@snapshot_id}")
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

    class StaContext

      def initialize(stahandler)
        raise "Invalid Class: #{stahandler}" unless stahandler.instance_of?(StaHandler)
        @sta = stahandler
      end

      def volume_id
        @sta.instance_variable_get(:@volume_id)
      end

      def snapshot_id
        @sta.instance_variable_get(:@snapshot_id)
      end

      def destination
        @sta.instance_variable_get(:@destination)
      end

      def volume
        @sta.instance_variable_get(:@volume)
      end

      def snapshot
        @sta.instance_variable_get(:@snapshot)
      end
      
      def node
        @sta.instance_variable_get(:@node)
      end
    end

  end
end
