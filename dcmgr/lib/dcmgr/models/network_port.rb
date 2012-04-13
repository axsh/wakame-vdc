# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class NetworkPort < BaseNew
    taggable 'port'

    many_to_one :network
    many_to_one :network_vif
    alias :vif :network_vif

    def validate
      super
    end

    def before_destroy
      super
    end
  end
end
