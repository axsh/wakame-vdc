# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class DcNetwork < Dcmgr::Endpoints::ResponseGenerator
    def initialize(dc_network)
      raise ArgumentError if !dc_network.is_a?(Dcmgr::Models::DcNetwork)
      @dc_network = dc_network
    end

    def generate()
      @dc_network.instance_exec {
        to_hash.merge(:id=>canonical_uuid)
      }
    end
  end

  class DcNetworkCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        DcNetwork.new(i).generate
      }
    end
  end
end
