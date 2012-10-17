# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Datacenter network definition
  class DcNetwork < BaseNew
    taggable('dcn')

    one_to_many :networks
    one_to_many :vlan_leases
    one_to_one :vlan, :class=>VlanLease

    plugin :serialization
    serialize_attributes :yaml, :offering_network_modes

    def vlan_network?
      !self.vlan_lease_id.nil?
    end

    def before_validation
      self.offering_network_modes ||= ['passthru']
      self.offering_network_modes.uniq!
      super
    end

    def validate
      unless self.name =~ /\A\w+\Z/
        errors.add(:name, "network name characters must be [A-Za-z0-9]: #{self.name}")
      end

      # Array#& operator conflicts with Sequel Query DSL....
      unknown_list = self.offering_network_modes.find_all{ |i| !Network::NETWORK_MODES.member?(i.to_sym) }
      unless unknown_list.empty?
        errors.add(:offering_network_modes, "Unknown network modes: #{unknown_list.join(', ')}")
      end

      super
    end

    def to_hash
      h = super
      h[:vlan_lease]=vlan.to_hash if self.vlan
      h
    end

  end
end
