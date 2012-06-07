# -*- coding: utf-8 -*-

module Dcmgr::Scheduler::HostNode::Rules

  class AccountLeastUsage < Rule

    def filter(dataset,instance)
      reorder(dataset.all,instance)
    end
    
    def reorder(array,instance)
      array.sort_by! { |hn|
        hn.instances.delete_if { |i| i.account != instance.account || i.state != "running" }.size
      }
      
      array
    end

  end

end
