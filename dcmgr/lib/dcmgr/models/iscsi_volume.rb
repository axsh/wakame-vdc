# -*- coding: utf-8 -*-

module Dcmgr::Models
  class IscsiVolume < BaseNew
    unrestrict_primary_key

    # StorageNode class uses class table inheritance plugin.
    many_to_one :iscsi_storage_node, :class=>StorageNode, :key=>:iscsi_storage_node_id
    one_to_one :volume, :key=>:id

    alias storage_node iscsi_storage_node
    
    def to_hash
      super().to_hash.merge(:iscsi_storage_node=>iscsi_storage_node.to_hash)
    end

    private
    def before_validation
      self.path ||= self.volume.canonical_uuid
      super
    end
    
  end
end
