# -*- coding: utf-8 -*-

require 'extlib/module'
require 'configuration'

module Dcmgr
  module Scheduler
    class SchedulerError < StandardError; end
    class HostNodeSchedulingError < SchedulerError; end
    class StorageNodeSchedulingError < SchedulerError; end
    class NetworkSchedulingError < SchedulerError; end

    # Scheduler factory based on the service type.
    class ServiceType
      def initialize(service_type_obj)
        st = if service_type_obj.respond_to?(:service_type)
               service_type_obj.service_type
             elsif [String, Symbol].member?(service_type_obj.class)
               service_type_obj.to_s
             else
               service_type_obj
             end
        if Dcmgr.conf.service_types[st.to_s].nil?
          raise "Unknown service type: #{service_type_obj}"
        end
        @service_type = st.to_s
      end

      def host_node
        c = Scheduler.scheduler_class(conf.host_node_scheduler.scheduler_class, ::Dcmgr::Scheduler::HostNode)
        c.new(conf.host_node_scheduler.option)
      end

      def host_node_ha
        c = Scheduler.scheduler_class(conf.host_node_ha_scheduler.scheduler_class, ::Dcmgr::Scheduler::HostNode)
        c.new(conf.host_node_ha_scheduler.option)
      end

      def storage_node
        c = Scheduler.scheduler_class(conf.storage_node_scheduler.scheduler_class, ::Dcmgr::Scheduler::StorageNode)
        c.new(conf.storage_node_scheduler.option)
      end
      
      def network
        c = Scheduler.scheduler_class(conf.network_scheduler.scheduler_class, ::Dcmgr::Scheduler::Network)
        c.new(conf.network_scheduler.option)
      end

      private
      def conf
        Dcmgr.conf.service_types[@service_type]
      end
    end

    def self.service_type(service_type)
      ServiceType.new(service_type)
    end

    # Factory method for HostNode scheduler
    def self.host_node()
      service_type(Dcmgr.conf.default_service_type).host_node
    end

    # Factory method for HostNode scheduler for HA
    def self.host_node_ha()
      service_type(Dcmgr.conf.default_service_type).host_node_ha
    end

    # Factory method for StorageNode scheduler
    def self.storage_node()
      service_type(Dcmgr.conf.default_service_type).storage_node
    end

    # Factory method for Network scheduler
    def self.network()
      service_type(Dcmgr.conf.default_service_type).network
    end

    # common scheduler class finder
    def self.scheduler_class(input, namespace)
      raise ArgumentError unless namespace.class == Module
      
      c = case input
          when Symbol
            namespace.const_get(input)
          when String
            if namespace.const_defined?(input)
              namespace.const_get(input)
            else
              Module.find_const(input)
            end
          else
            if input.is_a?(Class) && s.scheduler_class < Module.find_const("#{namespace.to_s}Scheduler")
              s.scheduler_class
            else
              raise ArgumentError, "Unknown scheduler identifier: #{input}"
            end
          end
      raise TypeError, "Invalid scheduler class ancestor: #{}" unless c < Module.find_const("#{namespace.to_s}Scheduler")
      c
    end

    # Allocate HostNode to Instance object.
    class HostNodeScheduler
      attr_reader :options
      
      def initialize(options=nil)
        @options = options
      end

      # @param Models::Instance instance
      # @return Models::HostNode
      def schedule(instance)
        raise NotImplementedError
      end
    end

    # Allocate StorageNode to Volume object.
    class StorageNodeScheduler
      attr_reader :options

      def initialize(options=nil)
        @options = options
      end
      
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
      attr_reader :options

      def initialize(options=nil)
        @options = options
      end

      # @param Models::HostNode host_node
      # @return Models::Network
      def schedule(instance)
        raise NotImplementedError
      end
    end
  end
end
