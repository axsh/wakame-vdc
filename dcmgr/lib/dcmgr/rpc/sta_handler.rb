# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'

module Dcmgr
  module Rpc

    class StaHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::ByteUnit

      def select_backing_store
        backing_store = Dcmgr.conf.backing_store
        @backing_store = Dcmgr::Drivers::BackingStore.select_backing_store(backing_store)
      end

      def select_iscsi_target
        iscsi_target = Dcmgr.conf.iscsi_target
        @iscsi_target = Dcmgr::Drivers::IscsiTarget.select_iscsi_target(iscsi_target, @node)
      end

      # Setup volume file from snapshot storage and register to
      # sotrage target.
      def setup_and_export_volume
        select_backing_store
        @sta_ctx = StaContext.new(self)

        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:creating, :export_path=>@volume[:uuid]})

        if @volume[:backup_object_id]
          begin
            snap_tmp_path = File.expand_path("#{@volume[:uuid]}.tmp", Dcmgr.conf.tmp_dir)

            @backup_object = @snapshot = rpc.request('sta-collector', 'get_backup_object', @volume[:backup_object_id])
            raise "Invalid backup_object state: #{@backup_object[:state]}" unless @backup_object[:state].to_s == 'available'

            begin
              # download backup object to the tmporary place.
              snapshot_storage = Drivers::BackupStorage.snapshot_storage(@backup_object[:backup_storage])
              logger.info("Downloading to #{@backup_object[:uuid]}: #{snap_tmp_path}")
              snapshot_storage.download(@backup_object, snap_tmp_path)
              logger.info("Finished downloading #{@backup_object[:uuid]}: #{snap_tmp_path}")
            rescue => e
              logger.error(e)
              raise "snapshot not downloaded"
            end
            logger.info("Creating new volume #{@volume_id} from #{@backup_object[:uuid]} (#{convert_byte(@volume[:size], MB)} MB)")

            @backing_store.create_volume(@sta_ctx, snap_tmp_path)
          ensure
            File.unlink(snap_tmp_path) rescue nil
          end

        else
          logger.info("Creating new empty volume #{@volume_id} (#{convert_byte(@volume[:size], MB)} MB)")
          @backing_store.create_volume(@sta_ctx, nil)
        end
        logger.info("Finished creating new volume #{@volume_id}.")

        logger.info("Registering to iscsi target: #{@volume_id}")
        select_iscsi_target
        opt = @iscsi_target.create(@sta_ctx)
        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:available, :transport_information=>opt})
        logger.info("Finished registering iscsi target: #{@volume_id}")
      end

      job :create_volume, proc {
        @volume_id = request.args[0]
        @volume = rpc.request('sta-collector', 'get_volume', @volume_id)
        raise "Invalid volume state: #{@volume[:state]}" unless @volume[:state].to_s == 'pending'

        setup_and_export_volume
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        logger.error("Failed to run create_volume: #{@volume_id}")
      }

      # create volume and chain to run instance.
      job :create_volume_and_run_instance, proc {
        @volume_id = request.args[0]
        @instance_id = request.args[1]

        @volume = rpc.request('sta-collector', 'get_volume', @volume_id)
        raise "Invalid volume state: #{@volume[:state]}" unless @volume[:state].to_s == 'pending'

        setup_and_export_volume

        @instance = rpc.request('hva-collector', 'get_instance', @instance_id)
        jobreq.submit("hva-handle.#{@instance[:host_node][:node_id]}", 'run_vol_store', @instance_id, @volume_id)
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_volume', @volume_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        rpc.request('hva-collector', 'update_instance', @instance_id, {:state=>:terminated, :terminated_at=>Time.now.utc})
        logger.error("Failed to run create_volume_and_run_instance: #{@instance_id}, #{@volume_id}")
      }

      job :delete_volume do
        @volume_id = request.args[0]
        @volume = rpc.request('sta-collector', 'get_volume', @volume_id)
        logger.info("#{@volume_id}: start deleting volume.")
        errcount = 0
        if @volume[:state].to_s == 'deleted'
          raise "#{@volume_id}: Invalid volume state: deleted"
        end
        if @volume[:state].to_s != 'deleting'
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
          logger.error("#{@volume_id}: Failed to delete volume: #{@volume[:storage_node][:export_path]}/#{@volume[:uuid]}")
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
        @volume_id = request.args[0]
        @backup_object_id = request.args[1]
        @backup_object = rpc.request('sta-collector', 'get_backup_object', @backup_object_id) unless @backup_object_id.nil?
        @volume = rpc.request('sta-collector', 'get_volume', @volume_id)
        @sta_ctx = StaContext.new(self)

        logger.info("create new snapshot: #{@backup_object_id}")
        raise "Invalid volume state: #{@volume[:state]}" unless %w(available attached).member?(@volume[:state].to_s)

        begin
          snapshot_storage = Dcmgr::Drivers::BackupStorage.snapshot_storage(@backup_object[:backup_storage])
          select_backing_store

          logger.info("Taking new snapshot for #{@volume_id}")
          @backing_store.create_snapshot(@sta_ctx)
          logger.info("Finish to create snapshot for #{@volume_id}")
          logger.info("Uploading #{@backup_object_id} to #{@backup_object[:backup_storage][:base_uri]}")
          snapshot_storage.upload(@backing_store.snapshot_path(@sta_ctx), @backup_object)
          logger.info("Finish to upload #{@backup_object_id}")
        rescue => e
          logger.error(e)
          raise "snapshot has not be uploaded"
        ensure
          @backing_store.delete_snapshot(@sta_ctx)
        end

        rpc.request('sta-collector', 'update_backup_object', @backup_object_id, {:state=>:available}) do |req|
          req.oneshot = true
        end
        logger.info("created new backup: #{@backup_object_id}")
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_backup_object', @backup_object_id, {:state=>:deleted, :deleted_at=>Time.now.utc})
        logger.error("Failed to run create_snapshot: #{@backup_object_id}")
      }

      job :delete_snapshot do
        @snapshot_id = request.args[0]
        @snapshot = rpc.request('sta-collector', 'get_snapshot', @snapshot_id)
        @volume = rpc.request('sta-collector', 'get_volume', @snapshot[:origin_volume_id])
        logger.info("deleting snapshot: #{@snapshot_id}")
        raise "Invalid snapshot state: #{@snapshot[:state]}" unless @snapshot[:state].to_s == 'deleting'
        begin
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

      def backup_object_id
        @sta.instance_variable_get(:@backup_object_id)
      end

      def destination
        @sta.instance_variable_get(:@destination)
      end

      def volume
        @sta.instance_variable_get(:@volume)
      end

      def backup_object
        @sta.instance_variable_get(:@backup_object)
      end

      def node
        @sta.instance_variable_get(:@node)
      end
    end

  end
end
