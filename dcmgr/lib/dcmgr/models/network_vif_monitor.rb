# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Network service monitor entry for vifs.
  class NetworkVifMonitor < BaseNew
    taggable 'nwm'

    many_to_one :network_vif

    subset(:alives, {:deleted_at => nil})

    plugin :serialization
    serialize_attributes :yaml, :params

    private

    def before_validation
      super
    end
    
    def _destroy_delete
      self.deleted_at ||= Time.now
      self.save_changes
    end

  end
end
