# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::HostNode::Rules

  class LeastUsageBy < Rule
    configuration do
      param :key
    end

    def filter(dataset,instance)
      reorder(dataset.all,instance)
    end
    
    def reorder(array,instance)
      array.sort_by! { |hn|
        hn.instances.delete_if { |i| i.request_params[options.key] != instance.request_params[options.key] || i.state == "terminated" || i.state == "stopped" }.size
      }
      
      array
    end

  end

end
