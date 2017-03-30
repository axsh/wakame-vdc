# -*- coding: utf-8 -*-

module Mussel
  class IpPool < Base
    def self.acquire(ipp_uuid, params)
      http_response = JSON.parse(`#{parse_params(params)} #{MUSSEL} #{class_name} acquire #{ipp_uuid}`)
      Responses.const_get(class_name.camelize).new(http_response)
    end
  end

  module Responses
    class IpPool < Base
    end
  end
end
