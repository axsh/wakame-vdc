# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr
  module HvcAccess
    def run_instance(hva_ip, instance_uuid,
                     cpus, cpu_mhz, memory, *opts)
      p [hva_ip, instance_uuid,
                     cpus, cpu_mhz, memory, opts]
    end
  end
  
  class HvcHttp
    include HvcAccess
    def open(host, port=80, &block)
      Net::HTTP.start(host, port) {|http|
        block.call(http)
      }
    end
  end
end
