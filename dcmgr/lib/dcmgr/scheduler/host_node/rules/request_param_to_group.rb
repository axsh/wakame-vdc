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
      tag_id = options.pairs[request_param] || options.default
      
      host_node_ids = Dcmgr::Models::Tag[tag_id].mapped_uuids.map { |tagmap| tagmap[:uuid] }
    end
  end
        
end
