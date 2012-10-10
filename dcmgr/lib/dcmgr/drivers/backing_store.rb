# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class BackingStore

      def create_volume(ctx, snapshot_file=nil)
        raise NotImplementedError
      end

      def delete_volume(ctx)
        raise NotImplementedError
      end

      # Take a snapshot where snapshot_path() addresses.
      # @param StaContext ctx
      def create_snapshot(ctx)
        raise NotImplementedError
      end

      # Delete a snapshot where snapshot_path() addresses.
      def delete_snapshot(ctx)
        raise NotImplementedError
      end

      # Generate a snapshot path using seed info.
      # It has to reproduce same result when the same parameters are given.
      # @param StaContext ctx
      # @return String absolute path to the snapshot
      def snapshot_path(ctx)
        raise NotImplemented
      end

      def self.select_backing_store(backing_store)
        case backing_store
        when "raw"
          bs = Dcmgr::Drivers::Raw.new
        when "zfs"
          bs = Dcmgr::Drivers::Zfs.new
        when "ifs"
          bs = Dcmgr::Drivers::Ifs.new
        else
          raise "Unknown backing_store type: #{backing_store}"
        end
        bs
      end
    end
  end
end
