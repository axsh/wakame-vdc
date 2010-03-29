# -*- coding: utf-8 -*-
  
require 'uri'
require 'cgi'
require 'active_support'
  
module Dcmgr
  class HvcHttpMock
    def hvas
      ret = {}
      HvController.all.each{|hvc|
        ret.merge! find_hvas_byhvc(hvc)
      }
      ret
    end

    def hva(hva_ip)
      self.hvas[hva_ip]
    end

    def find_hvas(host, port)
      url = "http://#{host}#{if port == 80 then "" else ":" + port.to_s end}/"
      hvc = HvController[:access_url=>url]
      return [] unless hvc
      find_hvas_byhvc(hvc)
    end

    def find_hvas_byhvc(hvc)
      ret = {}
      hvc.hv_agents.each{|hva|
        hva_data = HvaStore.new(hva.ip,
                           hva.instances)
        ret[hva.ip] = hva_data
      }
      ret
    end
    
    def open(host, port=3000, &block)
      hvas = find_hvas(host, port)
      conn = HvcHttpMockConnection.new(hvas)
      conn.extend HvcAccess
      block.call(conn)
    end

    class HvaStore
      def initialize(hva_ip, instances={})
        @ip = hva_ip
        @instances = {}
        add_instances(instances)
      end

      def dummy_instance_ip
        @@instance_ip ||= 0
        @@instance_ip += 1

        '192.168.2.%s' % @@instance_ip
      end
      
      def add_instances(instances)
        instances.each{|instance|
          add_instance(instance.ip, instance.uuid,
                       instance.status_sym)
        }
      end

      def add_instance(ip, uuid, status)
        unless ip
          raise "can't empty uuid" unless uuid
          ip = dummy_instance_ip
          instance = Instance[:uuid=>uuid]
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

        inst = Instance[uuid]
        if inst
          inst.status_sym= status
          inst.save
        end
        
        add_instance(ip, uuid, status)
      end

      attr_accessor :instances
    end
  end

  class HvcHttpMockConnection
    def initialize(hvas)
      @hvas = hvas
    end

    def get_response(path, params)
      return HvcHttpMockResponse.new(404, "") unless @hvas

      case path
      when '/instance/run_instance'
        hva_ip = params[:hva_ip]
        instance_uuid = params[:instance_uuid]
        raise "unkown hva ip: %s" % hva_ip unless @hvas[hva_ip]

        @hvas[hva_ip].update_instance(nil, instance_uuid, :online)
        HvcHttpMockResponse.new(200, "ok")
        
      when '/instance/terminate_instance'
        instance_uuid = params[:instance_uuid]
        @hvas.each_value{|hva|
          matched_instance = hva.instances.find{|inst| inst[1][0] == instance_uuid}
          next unless matched_instance
          hva.update_instance(matched_instance[0], matched_instance[1][0], :offline)
          return HvcHttpMockResponse.new(200, "ok")
        }
        HvcHttpMockResponse.new(404, "not found: #{path}")

      when '/instance/describe_instances'
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
        Dcmgr::logger.info "404, path: #{path}"
        HvcHttpMockResponse.new(404, "not found: #{path}")
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
