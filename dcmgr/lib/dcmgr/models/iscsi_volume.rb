# -*- coding: utf-8 -*-

module Dcmgr::Models
  class IscsiVolume < BaseNew
    unrestrict_primary_key
    
    many_to_one :iscsi_storage_node, :class=>IscsiStorageNode, :key=>:storage_node_id

    def to_hash
      v = self.to_hash.merge(:storage_node=>iscsi_storage_node.to_hash)
    end
  end
end
