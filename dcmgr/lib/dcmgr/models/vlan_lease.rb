# -*- coding: utf-8 -*-

module Dcmgr::Models
  # VLAN  lease information
  class VlanLease < AccountResource
    taggable 'vlan'

    one_to_many :networks

    def validate
      super
      
      unless 1 <= self.tag_id.to_i && self.tag_id.to_i <= 4095
        errors.add(:tag_id, "Tag ID is out of range (1-4095)")
      end
      
    end
  end
end
