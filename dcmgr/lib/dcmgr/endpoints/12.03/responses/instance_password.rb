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
      # TODO: Clear the password field at specified instances record
      #       if the flag delete_password_on_request flag is set.
    end
  end
end
