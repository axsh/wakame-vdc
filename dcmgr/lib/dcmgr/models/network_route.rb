# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class NetworkRoute < BaseNew

    ROUTE_TYPE_GATEWAY_OPENFLOW = 'gateway_openflow'
    ROUTE_TYPE_GATEWAY_INSTANCE = 'gateway_instance'
    ROUTE_TYPE_NAT_OPENFLOW     = 'nat_openflow'
    ROUTE_TYPE_NAT_INSTANCE     = 'nat_instance'

    SUPPORTED_ROUTE_TYPE = [ROUTE_TYPE_GATEWAY_OPENFLOW,
                            ROUTE_TYPE_GATEWAY_INSTANCE,
                            ROUTE_TYPE_NAT_OPENFLOW,
                            ROUTE_TYPE_NAT_INSTANCE,
                           ]

    many_to_one(:inner_vif, :key => :inner_vif_id, :class => NetworkVif)
    many_to_one(:outer_vif, :key => :outer_vif_id, :class => NetworkVif)

    def to_hash
      inner_nw = self.inner_vif.network
      outer_nw = self.outer_vif.network

      hash = {
        :type => self.type,
        :inner_vif => self.inner_vif.to_hash_flat,
        :inner_nw => inner_nw.nil? ? nil : {
          :ipv4 => inner_nw.ipv4_network,
          :prefix => inner_nw.prefix,
        },
        :outer_vif => self.outer_vif.to_hash_flat,
        :outer_nw => outer_nw.nil? ? nil : {
          :ipv4 => outer_nw.ipv4_network,
          :prefix => outer_nw.prefix,
        },
      }
    end

    def before_validation
      super

      unless SUPPORTED_ROUTE_TYPE.member?(self.type)
        errors.add(:route_type, "unknown route type: #{self.type}")
      end
    end

    def validate
      super
    end

    def before_destroy
      super
    end
  end
end
