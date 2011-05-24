# -*- coding: utf-8 -*-

module Dcmgr::Models
  # VLAN  lease information
  class VlanLease < AccountResource
    taggable 'vlan'

    inheritable_schema do
      Fixnum :tag_id, :null=>false

      index :tag_id, {:unique=>true}
    end
    with_timestamps

    one_to_many :networks

    def validate

      unless 1 <= self.tag_id.to_i && self.tag_id.to_id <= 4095
        errors.add(:tag_id, "Tag ID is out of range (1-4095)")
      end
      
    end
  end
end
