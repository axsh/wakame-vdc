# -*- coding: utf-8 -*-
require 'fuguta'

module Dcmgr
  module Drivers
    class BackingStore
      extend Fuguta::Configuration::ConfigurationMethods::ClassMethods

      def_configuration do
        # backup storage UUID exists locally.
        param :local_backup_storage_id, :default=>nil
      end

      # Retrive configuration section for this or child class.
      def self.driver_configuration
        Dcmgr.conf.backing_store
      end

      def driver_configuration
        Dcmgr.conf.backing_store
      end

      def local_backup_object?(backup_object_hash)
        driver_configuration.local_backup_storage_id &&
          driver_configuration.local_backup_storage_id == backup_object_hash[:backup_storage][:uuid]
      end

      def create_volume(ctx, snapshot_file=nil)
        raise NotImplementedError
      end

      def delete_volume(ctx)
        raise NotImplementedError
      end

      # The backing store class includes this interface
      # if it is capable to perform as a backup storage.
      #  i.e. if you want to deals with taken snapshot
      #       on the storage device as backup object.
      module ProvideBackupVolume
        # Create local backup from volume.
        # @param StaContext ctx
        def backup_volume(ctx)
          raise NotImplementedError
        end

        def delete_backup(ctx)
          raise NotImplementedError
        end

        # @return String path to the backup object key by backup_volume().
        #
        # backup_volume(ctx)
        # puts backup_object_key_created(ctx)
        def backup_object_key_created(ctx)
          raise NotImplementedError
        end
      end

      module ProvidePointInTimeSnapshot
        # Take a snapshot where snapshot_path() addresses.
        # @param StaContext ctx
        def create_snapshot(ctx)
          raise NotImplementedError
        end

        # Delete a snapshot where snapshot_path() addresses.
        def delete_snapshot(ctx)
          raise NotImplementedError
        end

        # Returns snapshot path string. It has to be called after create_snapshot().
        # and also be expected to return same value until create_snapshot() called again.
        # @param StaContext ctx
        # @return String path to the snapshot created by create_snapshot().
        #
        # create_snapshot(ctx)
        # puts snapshot_path_created(ctx)
        def snapshot_path_created(ctx)
          raise NotImplementedError
        end
      end

      # deprecated
      def self.select_backing_store(backing_store)
        driver_class(backing_store).new
      end

      def self.driver_class(backing_store)
        case backing_store.to_s
        when "raw"
          Dcmgr::Drivers::Raw
        when "zfs"
          Dcmgr::Drivers::Zfs
        when "ifs"
          Dcmgr::Drivers::Ifs
        else
          raise "Unknown backing_store type: #{backing_store}"
        end
      end
    end
  end
end
