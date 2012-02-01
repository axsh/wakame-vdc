# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class NetworkPort < BaseNew
    taggable 'port'

    many_to_one :network
    one_to_one :instance_nic

    def validate
      super
    end

    def before_destroy
      super
    end

    def to_api_document
      to_hash.merge({:id=>self.canonical_uuid, :attachment => {}})
    end

  end
end
