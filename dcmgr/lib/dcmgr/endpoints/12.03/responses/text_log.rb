# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class TextLog < Dcmgr::Endpoints::ResponseGenerator
    def initialize(text_log)
      @text_log = text_log
    end

    def generate
      h = {
        :id => @text_log[:id],
        :payload => @text_log[:message],
        :created_at => Time.now
      }
      h
    end
  end

  class TextLogCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      @ds = ds
    end

    def generate()
      @ds.map { |i|
        TextLog.new(i).generate
      }
    end
  end
end