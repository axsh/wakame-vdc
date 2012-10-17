# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class NetworkService < BaseNew

    many_to_one :network_vif

    def to_hash
      hash = super
      hash.merge!(self.network_vif.to_hash_flat)
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
