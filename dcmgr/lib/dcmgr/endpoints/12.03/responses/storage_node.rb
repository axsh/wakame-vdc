# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class StorageNode < Dcmgr::Endpoints::ResponseGenerator
    def initialize(storage_node)
      raise ArgumentError if !storage_node.is_a?(Dcmgr::Models::StorageNode)
      @storage_node = storage_node
    end

    def generate()
      @storage_node.instance_exec {
        to_hash.merge(:id=>canonical_uuid)
      }
    end
  end

  class StorageNodeCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        StorageNode.new(i).generate
      }
    end
  end
end
