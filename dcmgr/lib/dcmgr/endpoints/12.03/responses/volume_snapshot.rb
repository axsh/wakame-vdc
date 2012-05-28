# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class VolumeSnapshot < Dcmgr::Endpoints::ResponseGenerator
    def initialize(volume_snapshot)
      raise ArgumentError if !volume_snapshot.is_a?(Dcmgr::Models::VolumeSnapshot)
      @volume_snapshot = volume_snapshot
    end

    def generate()
      @volume_snapshot.instance_exec {
        to_hash.merge(:id=>canonical_uuid)
          .merge({:destination_id => self.destination,
                   :destination_name => self.display_name,
                   :storage_node_id => self.storage_node ? self.storage_node.canonical_uuid : nil,
                 })
      }
    end
  end

  class VolumeSnapshotCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        VolumeSnapshot.new(i).generate
      }
    end
  end
end
