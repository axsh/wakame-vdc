# -*- coding: utf-8 -*-

module Dcmgr; module Scheduler; module HostNode
  class FindFirst < HostNodeScheduler

    def schedule(instance)
      host_node = Models::HostNode.first
      raise HostNodeScheduleError if host_node.nil?
      instance.host_node = host_node
    end
  end
end; end; end
