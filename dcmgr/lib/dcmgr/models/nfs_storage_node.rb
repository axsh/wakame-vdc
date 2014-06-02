# -*- coding: utf-8 -*-

module Dcmgr::Models
  class NfsStorageNode < StorageNode
    include Dcmgr::Constants::StorageNode

    one_to_many :nfs_volumes, :class=>NfsVolume

    def_dataset_method(:volumes) do
      # TODO: better SQL....
      Volume.filter(:id=>NfsVolume.filter(:nfs_storage_node_id=>self.select(:id)).select(:id))
    end

    def volumes_dataset
      self.class.filter(:id=>self.pk).volumes
    end

    def associate_volume(volume, &blk)
      raise ArgumentError, "Invalid class: #{volume.class}" unless volume.class == Volume
      raise ArgumentError, "#{volume.canonical_uuid} has already been associated." unless volume.volume_type.nil?

      nfs_vol = NfsVolume.new(&blk)
      nfs_vol.id = volume.pk
      nfs_vol.nfs_storage_node = self
      nfs_vol.path = volume.canonical_uuid
      nfs_vol.save

      volume.volume_type = Dcmgr::Models::NfsVolume.to_s
      volume.save_changes
      self
    end
  end
end
