# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class HostNodeGroup < Dcmgr::Endpoints::ResponseGenerator
    def initialize(host_node_group)
      raise ArgumentError if !host_node_group.is_a?(Dcmgr::Tags::HostNodeGroup)
      @host_node_group = host_node_group
    end

    def generate()
      @host_node_group.instance_exec {
        to_hash.merge(
          :id=>canonical_uuid,
          :mapped_uuids => mapped_uuids.map {|mapping| mapping[:uuid]}
        )
      }
    end
  end

  class HostNodeGroupCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        HostNodeGroup.new(i).generate
      }
    end
  end
end
