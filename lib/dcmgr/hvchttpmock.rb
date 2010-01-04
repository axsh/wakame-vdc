# -*- coding: utf-8 -*-

module Dcmgr
  class HvcHttpMock
    def initialize
      @responses = {}
    end
    
    def add_response(host, port, path, status, body)
      key = [host, port]
      @responses[key] = [] unless @responses.include? key
      @responses[key].push [path, status, body]
    end
    
    def open(host, port, &block)
      block.call(HvcHttpMockConnection.new(@responses[[host, port]]))
    end
  end

  class HvcHttpMockConnection
    def initialize(responses)
      unless responses
        @response = []
      else
        @responses = responses
      end
    end

    def get(_path)
      unless @responses
        return HvcHttpMockResponse.new(404, "")
      end
      @responses.each{|path, status, body|
        if path.is_a? Regexp
          next unless path =~ _path
        else
          next unless path == _path
        end
        return HvcHttpMockResponse.new(status, body)
      }
      HvcHttpMockResponse.new(404, "not found")
    end
  end

  class HvcHttpMockResponse
    def initialize(status, body)
      @status = status
      @body = body
    end

    def success?
      @status == 200 && @body == "ok"
    end

    attr_accessor :body
  end
end
