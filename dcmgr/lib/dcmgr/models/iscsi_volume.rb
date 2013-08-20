# -*- coding: utf-8 -*-

module Dcmgr::Models
  class IscsiVolume < BaseNew
    unrestrict_primary_key
    
    many_to_one :iscsi_storage_node, :class=>IscsiStorageNode, :key=>:storage_node_id
    one_to_one :volume, :key=>:id
    
    def to_hash
      v = self.to_hash.merge(:storage_node=>iscsi_storage_node.to_hash)
    end

    private
    def before_validation
      self.path ||= self.volume.canonical_uuid
      super
    end
    
  end
end
