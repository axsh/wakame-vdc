# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class PhysicalNetwork < BaseNew
    taggable('pn')
    # :private : host local private bridge not connected to any physical interfaces.
    # :bridge : Linux bridge
    # :ovs  : openvswitch
    # :macvlan : Linux macvlan
    BRIDGE_TYPES=[:private, :ovs, :macvlan, :bridge].freeze
    
    one_to_many :networks
    one_to_many :vlan_leases
    one_to_one :vlan, :class=>VlanLease

    def vlan_network?
      !self.vlan_lease_id.nil?
    end

    def before_validation
      # apply default bridge name using name column.
      self.bridge ||= "br-#{self[:name].gsub(/\s/,'').downcase[0,16]}"
      super
    end

    def validate
      unless self.name =~ /\A\w+\Z/
        errors.add(:name, "network name characters must be [A-Za-z0-9]: #{self.name}")
      end

      unless BRIDGE_TYPES.member?(self.bridge_type.to_sym)
        errors.add(:bridge_type, "Unknown bridge type: #{self.bridge_type}")
      end
      
      # Linux network device name is allowed 16 bytes (=IF_NAMESIZ)
      if self.bridge.size > 16
        errors.add(:bridge, "bridge name is too long. (<= 16 bytes)")
      end

      super
    end

  end
end
