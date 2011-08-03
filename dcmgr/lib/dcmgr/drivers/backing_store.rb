# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class BackingStore

      def create_volume(ctx)
      end

      def delete_volume(ctx)
      end

      def create_snapshot(ctx)
      end

      def delete_snapshot(ctx)
      end

      def self.select_backing_store(backing_store)
        case backing_store
        when "zfs"
          bs = Dcmgr::Drivers::Zfs.new
        else
          raise "Unknown backing_store type: #{backing_store}"
        end
        bs
      end
    end
  end
end
