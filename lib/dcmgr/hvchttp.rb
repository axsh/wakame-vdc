# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr
  module HvcAccess
    def run_instance(hva_ip, instance_uuid, opts={})
      _post("/instance/run_instance",
            opts.dup.merge({:hva_ip=>hva_ip, :instance_uuid=>instance_uuid})
            )
    end
    
    def terminate_instance(hva_ip, instance_uuid, *opts)
      _post("/instance/terminate_instance",
            :hva_ip=>hva_ip,
            :instance_uuid=>instance_uuid,
            :opts=>opts)
    end

    def describe_instances(*opts)
      _post("/instance/describe_instances",
            :opts=>opts)
    end

    def _post(path, params)
      get_response(path, params)
    end
  end

  module JsonHvcAccess
    def get_response(path, request)
      require 'json'
      res = post(path, JSON.dump(request), {'Content-Type'=>'text/javascript'})
      if res.is_a? Net::HTTPSuccess
        JSON.load(res.body)
      else
        raise "Failed request to hvc: #{res}"
      end
    end
  end
  
  class HvcHttp
    def open(host, port=3000, &block)
      Net::HTTP.start(host, port) {|http|
        http.extend HvcAccess
        http.extend JsonHvcAccess
        block.call(http)
      }
    end
  end
end
