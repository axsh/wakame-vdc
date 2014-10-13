# -*- coding: utf-8 -*-

module Mussel
  class NetworkVif < Base
    def self.attach_external_ip(params, uuid)
      http_response = JSON.parse(`#{parse_params(params)} #{MUSSEL} #{class_name} attach_external_ip #{uuid}`)
      Responses.const_get(class_name.camelize).new(http_response)
    end
  end

  module Responses
    class NetworkVif < Base
    end
  end
end
