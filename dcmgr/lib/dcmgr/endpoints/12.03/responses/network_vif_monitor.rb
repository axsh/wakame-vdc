# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class NetworkVifMonitor < Dcmgr::Endpoints::ResponseGenerator
    def initialize(vifmon)
      raise ArgumentError if !vifmon.is_a?(Dcmgr::Models::NetworkVifMonitor)
      @vifmon = vifmon
    end

    def generate()
      @vifmon.instance_exec {
        to_hash.merge({:id=>canonical_uuid,
                        :params=>(self.params.is_a?(Hash) ? self.params : {})
                      })
      }
    end
  end

  class NetworkVifMonitorCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        NetworkVifMonitor.new(i).generate
      }
    end
  end
end
