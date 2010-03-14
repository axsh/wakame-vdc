# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr
  module HvcAccess
    def run_instance(hva_ip, instance_uuid, instance_ip_addresses, instance_mac_addresses,
                     cpus, cpu_mhz, memory, *opts)
      post(:action=>"run_instance",
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
      post(:action=>"terminate_instance",
           :hva_ip=>hva_ip,
           :instance_uuid=>instance_uuid,
           :opts=>opts)
    end

    def describe_instances(*opts)
      post(:action=>"describe_instances",
           :opts=>opts)
    end

    def post(params)
      request = params.reject{|k,v| k == :opts}
      if params[:opts].include? :url_only
        request
      else
        get_response(request)
      end
    end
  end
  
  class HvcHttp
    include HvcAccess
    def open(host, port=3000, &block)
      Net::HTTP.start(host, port) {|http|
        http.extend HvcAccess
        block.call(http)
      }
    end
  end
end
