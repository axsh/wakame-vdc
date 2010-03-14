# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr
  module HvcAccess
    def run_instance(hva_ip, instance_uuid, instance_ip_addresses, instance_mac_addresses,
                     cpus, cpu_mhz, memory, *opts)
      _post(:action=>"run_instance",
            :hva_ip=>hva_ip,
            :instance_uuid=>instance_uuid,
            :instance_ip_addresses=>instance_ip_addresses,
            :instance_mac_addresses=>instance_mac_addresses,
            :cpus=>cpus,
            :cpu_mhz=>cpu_mhz,
            :memory=>memory,
            :opts=>opts)
    end
    
    def terminate_instance(hva_ip, instance_uuid, *opts)
      _post(:action=>"terminate_instance",
            :hva_ip=>hva_ip,
            :instance_uuid=>instance_uuid,
            :opts=>opts)
    end

    def describe_instances(*opts)
      _post(:action=>"describe_instances",
            :opts=>opts)
    end

    def _post(params)
      request = params.reject{|k,v| k == :opts}
      if params[:opts].include? :url_only
        request
      else
        get_response(request)
      end
    end
  end

  module JsonHvcAccess
    def get_response(request)
      res = post('/', YAML.dump(request))
      if res.code == 200
        YAML.load(res.body)
      else
        nil
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
