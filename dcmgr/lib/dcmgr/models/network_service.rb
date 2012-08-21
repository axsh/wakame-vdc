# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class NetworkService < BaseNew

    many_to_one :network_vif

    def to_hash
      hash = super
      hash.merge!(self.network_vif.to_hash_flat)
    end

    def to_api_document
      vif = self.network_vif

      hash = {
        :name => self.name,
        :network_id => vif.network.canonical_uuid,
        :network_vif_id => vif.canonical_uuid,
        :address => vif.direct_ip_lease.first ? vif.direct_ip_lease.first.ipv4 : nil,
        :mac_addr => vif.pretty_mac_addr,
        :incoming_port => self.incoming_port,
        :outgoing_port => self.outcoming_port,
        :created_at => self.created_at,
        :updated_at => self.updated_at,
      }
    end

    def before_validation
      # Verify type_id.

      # Verify ip.

      # Verify ports.

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
