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
  end
end
