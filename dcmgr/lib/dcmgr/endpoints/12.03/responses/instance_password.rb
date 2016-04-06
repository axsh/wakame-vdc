# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class InstancePassword < Dcmgr::Endpoints::ResponseGenerator
    def initialize(instance)
      raise ArgumentError, "Instance must be a #{Dcmgr::Models::Instance}" if !instance.is_a?(Dcmgr::Models::Instance)
      @instance = instance
    end

    def generate
      {
        :id => @instance.canonical_uuid,
        :encrypted_password => @instance.encrypted_password
      }
    end
  end
end
