# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class PhysicalNetwork < Dcmgr::Endpoints::ResponseGenerator
    def initialize(physical_network)
      raise ArgumentError if !physical_network.is_a?(Dcmgr::Models::PhysicalNetwork)
      @physical_network = physical_network
    end

    def generate()
      @physical_network.instance_exec {
        to_hash.merge(:id=>canonical_uuid)
      }
    end
  end

  class PhysicalNetworkCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        PhysicalNetwork.new(i).generate
      }
    end
  end
end
