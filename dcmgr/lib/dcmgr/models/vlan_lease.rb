# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Tag VLAN (dot1q) lease information
  class VlanLease < AccountResource
    taggable 'vlan'

    many_to_one :dc_network, :before_set => proc { |ar, dcnet|
      dcnet.name ||= "#{ar.dc_network.name}.#{ar.tag_id}"
      # the parent dc network must be a normal network.
      dcnet.vlan_lease_id.nil?
    }

    def validate
      super

      unless 1 <= self.tag_id.to_i && self.tag_id.to_i <= 4095
        errors.add(:tag_id, "Tag ID is out of range (1-4095)")
      end

    end
  end
end
