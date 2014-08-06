# -*- coding: utf-8 -*-

require 'extlib/module'

module Dcmgr
  module Scheduler
    class SchedulerError < StandardError; end
    class HostNodeSchedulingError < SchedulerError; end
    class StorageNodeSchedulingError < SchedulerError; end
    class NetworkSchedulingError < SchedulerError; end
    class MacAddressSchedulerError < SchedulerError; end
    class IPAddressSchedulerError < SchedulerError; end

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
        if Dcmgr::Configurations.dcmgr.service_types[st.to_s].nil?
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

      def mac_address
        c = Scheduler.scheduler_class(conf.mac_address_scheduler.scheduler_class, ::Dcmgr::Scheduler::MacAddress)
        c.new(conf.mac_address_scheduler.option)
      end

      def ip_address
        c = Scheduler.scheduler_class(conf.ip_address_scheduler.scheduler_class, ::Dcmgr::Scheduler::IPAddress)
        c.new(conf.ip_address_scheduler.option)
      end

      private
      def conf
        Dcmgr::Configurations.dcmgr.service_types[@service_type]
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

    # Factory method for MAC Addres scheduler
    def self.mac_address()
      service_type(Dcmgr.conf.default_service_type).mac_address
    end

    # Factory method for IP Addres scheduler
    def self.ip_address()
      service_type(Dcmgr.conf.default_service_type).ip_address
    end

    # common scheduler class finder
    def self.scheduler_class(input, namespace)
      raise ArgumentError unless namespace.class == Module

      c = case input
          when Symbol
            namespace.const_get(input, false)
          when String
            if namespace.const_defined?(input, false)
              namespace.const_get(input, false)
            else
              Module.find_const(input)
            end
          else
            if input.is_a?(Class) && input < Module.find_const("#{namespace.to_s}Scheduler")
              input
            else
              raise ArgumentError, "Unknown scheduler identifier: #{input}"
            end
          end
      raise TypeError, "Invalid scheduler class ancestor: #{}" unless c < Module.find_const("#{namespace.to_s}Scheduler")
      c
    end

    module HostNode
      def self.scheduler_class(input)
        Scheduler.scheduler_class(input, self)
      end
    end

    module StorageNode
      def self.scheduler_class(input)
        Scheduler.scheduler_class(input, self)
      end
    end

    module Network
      def self.scheduler_class(input)
        Scheduler.scheduler_class(input, self)
      end

      def self.check_vifs_parameter_format(vifs)
        raise Dcmgr::Scheduler::NetworkSchedulingError, "Missing or badly formatted vifs request parameter" unless vifs.is_a?(Hash)

        vifs.each { |name, vif_template|
          raise Dcmgr::Scheduler::NetworkSchedulingError, "#{name.inspect} is not a valid vif name" unless name.is_a?(String)
          raise Dcmgr::Scheduler::NetworkSchedulingError, "#{vif_template.inspect} is not a valid vif template" unless vif_template.is_a?(Hash)
        }

        nil
      end
    end

    # Common base class for schedulers
    class SchedulerBase
      attr_reader :options

      def initialize(options=nil)
        @options = options
      end

      # helper method to create scheduler specific configuration class.
      #
      # Each scheduler can have configuration section in
      # dcmgr.conf. Each section is a Fuguta::Configuration class and
      # the class has to be defined as "Configuration" constant.
      #
      # Example below shows a network scheduler class with the local conf class:
      # class Scheduler1 < Dcmgr::Scheudler::NetworkScheduler
      #   class Configuration < Dcmgr::Configurations::Dcmgr::NetworkScheduler
      #     param :xxxx
      #     param :yyyy
      #   end
      # end
      #
      # The configuration loader retrieves the Configuration class
      # when the option section is loaded in dcmgr.conf.
      #
      # service_type("std") {
      #   network_scheduler(:Scheduler1) {
      #     # Here is the option section for Scheduler1 class.
      #     xxxx :value1
      #     config.yyyy = :value2
      #   }
      # }
      #
      # This helper method allows to define the local configuration class as below:
      # class Scheduler1 < Dcmgr::Scheudler::NetworkScheduler
      #   configuration do
      #     param :xxxx
      #     param :yyyy
      #   end
      # end
      def self.configuration(&blk)
        # create new configuration class if not exist.
        unless self.const_defined?(:Configuration, false)
          self.const_set(:Configuration, Class.new(self.configuration_class))
        end
        if blk
          self.const_get(:Configuration, false).instance_eval(&blk)
        end
      end


      def self.configuration_class
        c = self
        begin
          v = c.instance_variable_get(:@configuration_class)
          return v if v
        end while c = c.superclass
      end
    end

    # Allocate HostNode to Instance object.
    class HostNodeScheduler < SchedulerBase
      @configuration_class = Dcmgr::Configurations::Dcmgr::HostNodeScheduler

      # @param Models::Instance instance
      # @return Models::HostNode
      def schedule(instance)
        raise NotImplementedError
      end

      module AllowOverCommit
        # allow the instances over commit during HA event.
        def schedule_over_commit(instance)
          raise NotImplementedError
        end
      end
    end

    # Allocate StorageNode to Volume object.
    class StorageNodeScheduler < SchedulerBase
      @configuration_class = Dcmgr::Configurations::Dcmgr::StorageNodeScheduler

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
    class NetworkScheduler < SchedulerBase
      @configuration_class = Dcmgr::Configurations::Dcmgr::NetworkScheduler

      # @param Models::Instance instance
      def schedule(instance)
        raise NotImplementedError
      end
    end

    # Lease a mac address to a vnic
    class MacAddressScheduler < SchedulerBase
      @configuration_class = Dcmgr::Configurations::Dcmgr::MacAddressScheduler

      # @param Models::Network_vif
      def schedule(network_vif)
        raise NotImplementedError
      end
    end

    # Lease an ip address to a vnic
    class IPAddressScheduler < SchedulerBase
      @configuration_class = Dcmgr::Configurations::Dcmgr::IPAddressScheduler

      # @param Models::Network_vif
      def schedule(network_vif)
        raise NotImplementedError
      end
    end

  end
end
