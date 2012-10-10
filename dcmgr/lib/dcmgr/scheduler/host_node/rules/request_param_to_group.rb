# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::HostNode::Rules

  class RequestParamToGroup < Rule
    configuration do
      param :key
      param :default

      DSL do
        def pair(key,value)
          @config[:pairs] ||= {}
          @config[:pairs][key] = value
        end
      end
    end

    def filter(dataset,instance)
      host_node_ids = get_host_node_ids(instance).map {|hid| Dcmgr::Models::HostNode.trim_uuid(hid) }

      dataset.filter(:uuid => host_node_ids)
    end

    def reorder(array,instance)
      host_node_ids = get_host_node_ids(instance)

      array.delete_if {|hn| not host_node_ids.member?(hn.canonical_uuid) }
    end

    private
    def get_host_node_ids(instance)
      request_param = instance.request_params[options.key]

      begin
        raise NoMethodError if options.default.nil?
      rescue NoMethodError => e
        raise Dcmgr::Scheduler::HostNodeSchedulingError, "No default host node group set"
      end

      tag_id = options.pairs[request_param] || options.default rescue options.default
      host_node_group = Dcmgr::Tags::HostNodeGroup[tag_id]

      raise Dcmgr::Scheduler::HostNodeSchedulingError, "Unknown host node group: #{tag_id}" if host_node_group.nil?

      host_node_ids = host_node_group.mapped_uuids.map { |tagmap| tagmap[:uuid] }
    end
  end

end
