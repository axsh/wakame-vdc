# -*- coding: utf-8 -*-
module DcmgrResource::V1203
  class StorageNode < Base
    def self.list(params = {})
      self.find(:all,:params => params)
    end
    
    def self.show(storage_node_id)
      self.get(storage_node_id)
    end
  end
end
