# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module HostNode

      # Find host node which has the same request_params[:host_node_id].
      class SpecifyNode < HostNodeScheduler
        include Dcmgr::Logger

        def schedule(instance)
          host_uuid = instance.request_params[:host_id] || instance.request_params[:host_pool_id]
          ds = Models::HostNode.online_nodes.filter(:uuid=>Models::HostNode.trim_uuid(host_uuid))

          host_node = ds.first

          raise HostNodeSchedulingError if host_node.nil?
          instance.host_node = host_node
        end
      end
    end
  end
end
