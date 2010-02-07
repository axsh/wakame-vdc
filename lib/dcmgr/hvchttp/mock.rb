# -*- coding: utf-8 -*-
  
require 'uri'
require 'cgi'
require 'active_support'
  
module Dcmgr
  class HvcHttpMock
    def initialize(host, port=80)
      if host.is_a? HvController
        hvc = host
        @host = hvc.ip
        @port = port
        @hvas = Hash[*hvc.hv_agents.map{|hva|
                       hva_data = Hva.new(hva.ip)
                       hva.instances.each{|ins|
                         hva_data.add_instance(ins.ip, ins.uuid, ins.status_sym)
                       }
                       [hva.ip, hva_data]
                     }.flatten]
      else
        @host = host
        @port = port
        @hvas = {}
      end
    end

    def add_hva(hva_ip)
      @hvas[hva_ip] = Hva.new(hva_ip)
    end

    def add_instance(instance)
      hva_ip = instance[:hva]
      hva = @hvas[hva_ip]
      instance_uuid, instance_ip = instance[:uuid], instance[:ip]
      hva.add_instance(instance_ip, instance_uuid, instance[:status])
    end

    def hva(ip)
      @hvas[ip]
    end

    attr_accessor :hvas
          
    def open(host, port=80, &block)
      if host == @host && port == @port
        hvas = @hvas
      else
        hvas = nil
      end
      conn = HvcHttpMockConnection.new(self)
      conn.extend HvcAccess
      block.call(conn)
    end
    
    class Hva
      def initialize(hva_ip)
        @ip = hva_ip
        @instances = {}
      end

      def dummy_instance_ip
        @@instance_ip ||= 0
        @@instance_ip += 1
        '192.168.2.%s' % @@instance_ip
      end
      
      def add_instance(ip, uuid, status)
        p [ip, uuid, status]
        unless ip
          raise "can't empty uuid" unless uuid
          ip = dummy_instance_ip
          instance = Instance[uuid]
          instance.ip = ip
          instance.save
        end
        
        @instances[ip] = [uuid, status]
      end

      def update_instance(ip, uuid=nil, status=nil)
        unless ip
          @instances.each{|_ip, inst|
            next unless inst[0] == uuid
            cur_uuid, cur_status = inst
            ip = _ip
            break
          }
        else
          cur_uuid, cur_status = @instances[ip]
        end

        uuid ||= cur_uuid
        status ||= cur_status
        add_instance(ip, uuid, status)
      end

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

      query = CGI.parse(uri.query) if uri.query
      action = query["action"].first if query

      case action
      when 'run_instance'
        hva_ip = query['hva_ip'].first
        instance_uuid = query['instance_uuid'].first
        raise "unkown hva ip: %s" % hva_ip unless @hvas[hva_ip]

        @hvas[hva_ip].update_instance(nil, instance_uuid, :online)
        HvcHttpMockResponse.new(200, "ok")
        
      when 'terminate_instance'
        instance_uuid = query['instance_uuid'].first
        @hvas.each_value{|hva|
          matched_instance = hva.instances.find{|inst| inst[1][0] == instance_uuid}
          next unless matched_instance
          hva.update_instance(matched_instance[0], matched_instance[1][0], :offline)
          return HvcHttpMockResponse.new(200, "ok")
        }
        HvcHttpMockResponse.new(404, "not found: #{query.inspect}")

      when 'describe_instances'
        ret = {}
        @hvas.each{|hva_ip, hva|
          ret_instances = {}
          hva.instances.each{|ip, ret_instance|
            ret_instances[ip] = {:uuid=>ret_instances[0],
              :status=>ret_instance[1]}
          }
          ret[hva_ip] = {
            'status'=>:online,
            'instances'=>ret_instances}
        }
        HvcHttpMockResponse.new(200, ret.to_json)
        
      else
        Dcmgr::logger.info "404: #{uri.path}"
        HvcHttpMockResponse.new(404, "not found: #{query}")
      end
    end
  end

  class HvcHttpMockResponse
    def initialize(status, body)
      @status = status
      @body = body
    end

    def code
      @status.to_s
    end

    def success?
      @status == 200
    end

    attr_accessor :body
    attr_accessor :status
  end
end
