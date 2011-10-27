# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module HostNode

      class ExcludeSame < HostNodeScheduler
        include Dcmgr::Logger

        def schedule(instance)
          ds = Models::HostNode.online_nodes.filter(:arch=>instance.spec.arch,
                                                    :hypervisor=>instance.spec.hypervisor)

          host_node = ds.all.find_all { |hn|
            hn.node_id != instance.host_node.node_id
          }.first

          raise HostNodeSchedulingError if host_node.nil?
          instance.host_node = host_node
        end
      end
    end
  end
end
