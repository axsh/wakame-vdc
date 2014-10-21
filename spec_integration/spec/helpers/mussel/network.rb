# -*- coding: utf-8 -*-

module Mussel
  class Network < Base
    def self.create(params)
      super(params)
    end

    def self.add_services(network_uuid, params)
      http_response = JSON.parse(`#{parse_params(params)} #{MUSSEL} #{class_name} add_services #{network_uuid}`)
      Responses.const_get(class_name.camelize).new(http_response)
    end
  end

  module Responses
    class Network < Base
    end
  end
end
