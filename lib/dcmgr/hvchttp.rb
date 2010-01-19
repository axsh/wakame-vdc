# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr
  class HvcHttp
    def open(host, port=80, &block)
      Net::HTTP.start(host, port) {|http|
        block.call(http)
      }
    end
  end
end
