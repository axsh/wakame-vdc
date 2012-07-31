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

    def filter_collection(response, result_type)
      [{ :total => @array.first['total'],
         :start => @array.first['start'],
         :limit => @array.first['limit'],
         :results => @array.first['results'].map { |i| result_type.new(i).generate }
       }]
    end
  end
end
