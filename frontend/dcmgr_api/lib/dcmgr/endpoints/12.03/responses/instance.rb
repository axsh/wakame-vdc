# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Instance < Dcmgr::Endpoints::ResponseGenerator
    def initialize(instance)
      raise ArgumentError if !instance.is_a?(Hash)
      @instance = instance
    end

    def generate()
      result = filter_response(@instance, [:id,
                                           :host_node,
                                           :cpu_cores,
                                           :memory_size,
                                           :arch,
                                           :image_id,
                                           :created_at,
                                           :state,
                                           :status,
                                           :ssh_key_pair,
                                           :hostname,
                                           :ha_enabled,
                                           :hypervisor,
                                           :display_name,
                                          ])
      result
    end
  end

  class InstanceCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(array)
      raise ArgumentError if !array.is_a?(Array)
      @array = array
    end

    def generate()
      filter_collection(@array, Instance)
    end
  end

end
