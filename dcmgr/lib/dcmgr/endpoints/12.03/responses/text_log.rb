# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class TextLog < Dcmgr::Endpoints::ResponseGenerator
    def initialize(text_log)
      raise ArgumentError if !text_log.is_a?(Dcmgr::Models::TextLog)
      @text_log = text_log
    end

    def generate
      @text_log.instance_exec {
        to_hash.merge(
          :id => id,
          :resource_type => resource_type,
          :payload => payload,
          :created_at => Time.at(created_at)
        )
      }
    end
  end

  class TextLogCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        TextLog.new(i).generate
      }
    end
  end
end