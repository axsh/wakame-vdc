# -*- coding: utf-8 -*-
require 'uri'
require 'cgi'
require 'json'

module Dcmgr
  class HvcHttpMock
    def initialize(host, port=80)
      @host = host
      @port = port
      @hvas = {}
    end

    def add_hva(hva_ip)
      @hvas[hva_ip] = Hva.new(hva_ip)
    end

    def add_instance(instance)
      hva_ip = instance[:hva]
      hva = @hvas[hva_ip]
      hva.add_instance(instance[:ip], instance[:status])
    end

    def hva(ip)
      @hvas[ip]
    end

    attr_accessor :hvas
          
    def open(host, port, &block)
      if host == @host && port == @port
        hvas = @hvas
      else
        hvas = nil
      end
      block.call(HvcHttpMockConnection.new(self))
    end
    
    class Hva
      def initialize(hva_ip)
        @ip = hva_ip
        @instances = {}
      end

      def add_instance(ip, status)
        @instances[ip] = status
      end

      alias :update_instance :add_instance

      attr_accessor :instances
    end
  end

  class HvcHttpMockConnection
    def initialize(hva_http)
      @hva_http = hva_http
      @hvas = hva_http.hvas
    end

    def get(path)
      return HvcHttpMockResponse.new(404, "") unless @hvas
      uri = URI(path)

      case uri.path
      when '/run_instance'
        query = CGI.parse(uri.query)
        hva_ip = query['hva_ip'][0]
        @hvas[hva_ip].add_instance(hva_ip, :online)
        HvcHttpMockResponse.new(200, "ok")
      when '/terminate_instance'
        query = CGI.parse(uri.query)
        instance_ip = query['instance_ip'][0]
        @hvas.each_value{|hva|
          next unless hva.instances.key? instance_ip
          hva.update_instance(instance_ip, :offline)
          return HvcHttpMockResponse.new(200, "ok")
        }
        HvcHttpMockResponse.new(404, "not found")

      when '/describe_instances'
        ret = {}
        @hvas.each{|hva_ip, hva|
          ret_instances = {}
          hva.instances.each{|ip, status|
            ret_instances[ip] = {:status=>status.to_s}
          }
          ret[hva_ip] = {
            'status'=>:online,
            'instances'=>ret_instances}
        }
        HvcHttpMockResponse.new(200, JSON.unparse(ret))
      else
        HvcHttpMockResponse.new(404, "not found")
      end
    end
  end

  class HvcHttpMockResponse
    def initialize(status, body)
      @status = status
      @body = body
    end

    def success?
      @status == 200
    end

    attr_accessor :body
    attr_accessor :status
  end
end
