# -*- coding: utf-8 -*-

module Dcmgr::Models
  class IscsiStorageNode < StorageNode
    include Dcmgr::Constants::StorageNode

    one_to_many :volumes, :class=>:IscsiVolume
    
    def validate
      super
    end
  end
end
