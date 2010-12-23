# -*- coding: utf-8 -*-

module Dcmgr::Models
  # VLAN  lease information
  class VlanLease < AccountResource
    taggable 'vlan'

    inheritable_schema do
      Fixnum :tag_id, :null=>false
      Fixnum :network_id, :null=>false
      index [:account_id, :tag_id], {:unique=>true}
    end
    with_timestamps

    one_to_many :network
  end
end
