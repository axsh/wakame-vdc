# -*- coding: utf-8 -*-

module Dcmgr::Endpoints
  class ResponseGenerator
    def generate()
      raise NotImplementedError
    end

    def filter_response(response, whitelist)
      result = {}
      whitelist.each { |key| result[key] = response[key.to_s] }
      result
    end
  end
end
