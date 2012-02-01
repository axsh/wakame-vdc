# -*- coding: utf-8 -*-

module Dcmgr::Models
  # Physical network interface
  class NetworkPort < BaseNew
    taggable 'port'

    many_to_one :network
    many_to_one :instance_nic

    def validate
      super
    end

    def before_destroy
      super
    end

    def to_api_document
      api_hash = to_hash
      api_hash.delete(:instance_nic_id)
      api_hash.merge({:id=>self.canonical_uuid,
                      :attachment => self.instance_nic.nil? ? {} : {"id" => self.instance_nic.canonical_uuid}})
    end

  end
end
