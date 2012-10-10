# -*- coding: utf-8 -*-

module Dcmgr
  module Scheduler
    module StorageNode

      # Find storage node which has the largest available disk space.
      class LeastUsage < StorageNodeScheduler
        include Dcmgr::Logger

        def schedule(volume)
          storage_node = Models::StorageNode.online_nodes.all.find_all { |s|
            s.free_disk_space >= volume.size
          }.sort_by { |s|
            s.free_disk_space
          }.reverse.first
          raise StorageNodeSchedulingError if storage_node.nil?
          volume.storage_node = storage_node
        end
      end
    end
  end
end
