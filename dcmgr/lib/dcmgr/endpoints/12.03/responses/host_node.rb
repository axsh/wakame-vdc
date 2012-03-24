# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class HostNode < Dcmgr::Endpoints::ResponseGenerator
    def initialize(host_node)
      raise ArgumentError if !host_node.is_a?(Dcmgr::Models::HostNode)
      @host_node = host_node
    end

    def generate()
      @host_node.instance_exec {
        to_hash.merge(:id=>canonical_uuid)
      }
    end
  end

  class HostNodeCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        HostNode.new(i).generate
      }
    end
  end
end
