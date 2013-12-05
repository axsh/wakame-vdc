# -*- coding: utf-8 -*-

module Dcmgr; module Scheduler; module StorageNode
  class FindFirst < StorageNodeScheduler

    protected
    def schedule_node(volume)
      params = volume.request_params

      Models::StorageNode.first.associate_volume(volume)
    end
  end
end; end; end
