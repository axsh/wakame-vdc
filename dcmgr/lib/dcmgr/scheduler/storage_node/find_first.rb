# -*- coding: utf-8 -*-

module Dcmgr; module Scheduler; module StorageNode
  class FindFirst < StorageNodeScheduler

    protected
    def schedule_node(volume)
      params = volume.request_params

      volume.storage_node = Models::StorageNode.first
    end
  end
end; end; end
