# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class NetworkRoute < BaseNew

    many_to_one(:inner_vif, :key => :inner_vif_id, :class => NetworkVif)
    many_to_one(:outer_vif, :key => :outer_vif_id, :class => NetworkVif)

    def to_hash
      inner_nw = self.inner_vif.network
      outer_nw = self.outer_vif.network

      hash = {
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
    end

    def validate
      super
    end

    def before_destroy
      super
    end
  end
end
