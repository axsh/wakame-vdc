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
        # [TODO] Should select backing_store type.
        backing_store = 'zfs'
        @backing_store = Dcmgr::Drivers::BackingStore.select_backing_store(backing_store)
      end

      def select_iscsi_target
        # [TODO] Should select backing_store type.
        #iscsi_target = 'sun_iscsi'
        iscsi_target = 'comstar'
        @iscsi_target = Dcmgr::Drivers::IscsiTarget.select_iscsi_target(iscsi_target)
      end

      job :create_volume do
        @volume_id = request.args[0]
        @destination = Dcmgr::StorageService.repository(request.args[1])
        @volume = rpc.request('sta-collector', 'get_volume', @volume_id)
        raise "Invalid volume state: #{@volume[:state]}" unless @volume[:state].to_s == 'registering'

        unless @volume[:snapshot_id].nil?
          @snapshot = rpc.request('sta-collector', 'get_snapshot', @volume[:snapshot_id])
          raise "Invalid snapshot state: #{@snapshot[:state]}" unless @snapshot[:state].to_s == 'available'
        end
        logger.info("creating new volume #{@volume_id}")

        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:creating, :export_path=>@volume[:uuid]})

        select_backing_store
        @backing_store.create_volume(StaContext.new(self))

        select_iscsi_target
        opt = @iscsi_target.create(StaContext.new(self))
        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:available, :transport_information=>opt})
        logger.info("registered iscsi target: #{@volume_id}")
      end

      job :delete_volume do
        @volume_id = request.args[0]
        @volume = rpc.request('sta-collector', 'get_volume', @volume_id)
        logger.info("#{@volume_id}: start deleting volume.")
        errcount = 0
        if @volume[:state].to_s == 'deleted'
          raise "#{@volume_id}: Invalid volume state: deleted"
        end
        if @volume[:state].to_s != 'deregistering'
          logger.warn("#{@volume_id}: Unexpected volume state but try again: #{@volume[:state]}")
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
          logger.error("#{@volume_id}: Failed to delete zfs volume: #{@volume[:storage_pool][:export_path]}/#{@volume[:uuid]}")
          errcount += 1
        end

        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        if errcount > 0
          logger.info("#{@volume_id}: Encountered one or more errors during deleting.")
        else
          logger.info("#{@volume_id}: Deleted volume successfully.")
        end
      end

      job :create_snapshot do
        @snapshot_id = request.args[0]
        @destination = Dcmgr::StorageService.repository(request.args[1])
        @snapshot = rpc.request('sta-collector', 'get_snapshot', @snapshot_id) unless @snapshot_id.nil?
        @volume = rpc.request('sta-collector', 'get_volume', @snapshot[:origin_volume_id])
        logger.info("create new snapshot: #{@snapshot_id}")
        raise "Invalid volume state: #{@volume[:state]}" unless @volume[:state].to_s == 'available' || @volume[:state].to_s == 'attached'

        select_backing_store
        @backing_store.create_snapshot(StaContext.new(self))

        rpc.request('sta-collector', 'update_snapshot', @snapshot_id, {:state=>:available})
        logger.info("created new snapshot: #{@snapshot_id}")
      end

      job :delete_snapshot do
        @snapshot_id = request.args[0]
        @destination = Dcmgr::StorageService.repository(request.args[1])
        @snapshot = rpc.request('sta-collector', 'get_snapshot', @snapshot_id)
        @volume = rpc.request('sta-collector', 'get_volume', @snapshot[:origin_volume_id])
        logger.info("deleting snapshot: #{@snapshot_id}")
        raise "Invalid snapshot state: #{@snapshot[:state]}" unless @snapshot[:state].to_s == 'deleting'

        select_backing_store
        @backing_store.delete_snapshot(StaContext.new(self))

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

    end

  end
end
