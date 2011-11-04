# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module HostNode

      # Find host node which has the same request_params[:host_node_id].
      class SpecifyNode < HostNodeScheduler
        include Dcmgr::Logger

        def schedule(instance)
          ds = Models::HostNode.online_nodes.filter(:arch=>instance.spec.arch,
                                                    :hypervisor=>instance.spec.hypervisor)

          host_node = ds.all.find_all { |hn|
            hn.node_id == instance.request_params[:host_node_id]
          }.first

          raise HostNodeSchedulingError if host_node.nil?
          instance.host_node = host_node
        end
      end
    end
  end
end
