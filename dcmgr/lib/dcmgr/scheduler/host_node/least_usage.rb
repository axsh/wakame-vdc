# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module HostNode

      # Find host node which has the largest available capacity.
      class LeastUsage < HostNodeScheduler
        include Dcmgr::Logger

        def schedule(instance)
          ds = Models::HostNode.online_nodes.filter(:arch=>instance.spec.arch,
                                                    :hypervisor=>instance.spec.hypervisor)

          host_node = ds.all.find_all { |hn|
            hn.available_cpu_cores >= instance.cpu_cores && \
              hn.available_memory_size >= instance.memory_size
          }.sort_by { |hn|
            hn.available_memory_size
          }.reverse.first

          raise HostNodeSchedulingError if host_node.nil?
          instance.host_node = host_node
        end
      end
    end
  end
end
