# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/alarm'

module Dcmgr::Endpoints::V1203::Responses
  class Alarm < Dcmgr::Endpoints::ResponseGenerator
    def initialize(object)
      raise ArgumentError if !object.is_a?(Dcmgr::Models::Alarm)
      @object = object
    end

    def generate()
      api_hash = @object.to_hash
      api_hash
    end
  end

    class AlarmCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |al|
        Alarm.new(al).generate
      }
    end
  end

end
