# -*- coding: utf-8 -*-

require 'extlib/module'

module Dcmgr
  module Scheduler
    class SchedulerError < StandardError; end
    class HostNodeSchedulingError < SchedulerError; end
    class StorageNodeSchedulingError < SchedulerError; end
    class NetworkSchedulingError < SchedulerError; end

    # Factory method for HostNode scheduler
    def self.host_node()
      c = scheduler_class(Dcmgr.conf.host_node_scheduler, ::Dcmgr::Scheduler::HostNode)
      c.new
    end

    # Factory method for HostNode scheduler for HA
    def self.host_node_ha()
      c = scheduler_class(Dcmgr.conf.host_node_ha_scheduler, ::Dcmgr::Scheduler::HostNode)
      c.new
    end

    # Factory method for StorageNode scheduler
    def self.storage_node()
      c = scheduler_class(Dcmgr.conf.storage_node_scheduler, ::Dcmgr::Scheduler::StorageNode)
      c.new
    end

    # Factory method for Network scheduler
    def self.network()
      c = scheduler_class(Dcmgr.conf.network_scheduler, ::Dcmgr::Scheduler::Network)
      c.new
    end

    # common scheduler class finder
    def self.scheduler_class(input, namespace)
      c = case input
          when Symbol
            namespace.const_get(input)
          else
            raise "Unknown #{namespace.to_s} scheduler: #{input}"
          end
      raise TypeError unless c < Module.find_const("#{namespace.to_s}Scheduler")
      c
    end

    # Allocate HostNode to Instance object.
    class HostNodeScheduler
      # @param Models::Instance instance
      # @return Models::HostNode
      def schedule(instance)
        raise NotImplementedError
      end
    end

    # Allocate StorageNode to Volume object.
    class StorageNodeScheduler
      # @param Models::Volume volume
      # @return nil
      def schedule(volume)
        if volume.snapshot_id
          # use same same storage node if it is local snapshot.
          if volume.snapshot.destination == 'local'
            volume.storage_node = Models::StorageNode[volume.snapshot.storage_node_id]
          else
            schedule_node(volume)
          end
        else
          schedule_node(volume)
        end
        raise StorageNodeSchedulingError if volume.storage_node.nil?
      end

      protected
      def schedule_node(volume)
        raise NotImplementedError
      end
    end

    # Manage vnic for instances and assign network object.
    class NetworkScheduler
      # @param Models::HostNode host_node
      # @return Models::Network
      def schedule(instance)
        raise NotImplementedError
      end
    end

  end
end
