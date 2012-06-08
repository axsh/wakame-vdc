# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::HostNode::Rules
      
  class AssignSpecToGroup < Rule
    configuration do
      param :mappings, :default => {}
      param :default
    end
    
    def filter(dataset,instance)
      if options.mappings.keys.member?(instance.spec.canonical_uuid)
        tag_id = options.mappings[instance.spec.canonical_uuid]
      else
        tag_id = options.default
      end
      host_node_ids = Dcmgr::Models::Tag[tag_id].mapped_uuids.map { |tagmap| Dcmgr::Models::HostNode.trim_uuid(tagmap[:uuid]) }
      
      dataset.filter(:uuid => host_node_ids)
    end
    
    def reorder(array,instance)
      array
    end
    
  end
        
end
