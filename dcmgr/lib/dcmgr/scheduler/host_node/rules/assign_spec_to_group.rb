# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::HostNode::Rules
      
  class AssignSpecToGroup < Rule
    configuration do
      param :template, :default => {}
    end
    
    def filter(dataset,instance)
      #spec_id = instance.spec.canonical_uuid
      # Filter based on group... no groups implemented yet so just return the dataset
      
      dataset
    end
    
    def reorder(array,instance)
      array
    end
    
  end
        
end
