# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    # Configuration loader for dcmgr.conf.
    class Dcmgr < Configuration

      class Scheduler < Configuration
        alias_param  :scheduler, :scheduler_class
        param :scheduler_class
        param :option

        def validate(errors)
          unless @config[:scheduler_class]
            errors << "Missing scheduler_class parameter"
          end
        end

        DSL do
          def self.load_section(class_name, conf_base_class, sched_namespace, &blk)
            raise ArgumentError unless conf_base_class < ::Dcmgr::Configuration
            raise ArgumentError unless ::Dcmgr::Scheduler::NAMESPACES.member?(sched_namespace)
            
            c = ::Dcmgr::Scheduler.scheduler_class(class_name, sched_namespace)
            s = Scheduler.new.parse_dsl do
              config.scheduler_class = c
            end
            
            if c.const_defined?(:Configuration)
              c = c.const_get(:Configuration)
              if c && c < conf_base_class
                c = c.new
                c.parse_dsl(&blk) if blk
                s.parse_dsl do
                  option c
                end
              end
            end
            s
          end
        end
      end

      # Optional parameter base classes for respective scheduler
      # types.
      # class Dcmgr::Scheduler::HostNode::Example
      #   class Configuration < Dcmgr::Configurations::HostNodeScheduler
      #     param :xxxx
      #   end
      #
      #   def schedule(instance)
      #     p options.xxxx
      #   end
      # end
      class HostNodeScheduler < Configuration
      end

      class StorageNodeScheduler < Configuration
      end

      class NetworkScheduler < Configuration
      end

      class ServiceType < Configuration
        def initialize(service_type)
          super()
          @config[:name] = service_type
        end
        
        def validate(errors)
          errors << "Missing name parameter" unless @config[:name]
        end

        DSL do
          def host_node_scheduler(class_name, &blk)
            @config[:host_node_scheduler] = Scheduler::DSL.load_section(class_name, HostNodeScheduler, ::Dcmgr::Scheduler::HostNode, &blk)
            self
          end

          def host_node_ha_scheduler(class_name, &blk)
            @config[:host_node_ha_scheduler] = Scheduler::DSL.load_section(class_name, HostNodeScheduler, ::Dcmgr::Scheduler::HostNode, &blk)
            self
          end
          
          def storage_node_scheduler(class_name, &blk)
            @config[:storage_node_scheduler] = Scheduler::DSL.load_section(class_name, StorageNodeScheduler, ::Dcmgr::Scheduler::StorageNode, &blk)
            self
          end

          def network_scheduler(class_name, &blk)
            @config[:network_scheduler] = Scheduler::DSL.load_section(class_name, NetworkScheduler, ::Dcmgr::Scheduler::Network, &blk)
            self
          end
        end
      end

      class StdServiceType < ServiceType
      end

      class LbServiceType < ServiceType
        param :image_id
        param :instance_spec_id
        param :host_node_id
        param :security_group
        param :ssh_key_id
      end 

      DSL do
        #
        # service_type("lb") {
        #   host_node_scheduler(:LbScheduler1) {}
        #   storage_node_scheduler(:LbScheduler1) {}
        #   network_scheduler(:LbScheduler1) {}
        # }
        def service_type(name, class_name, &blk)
          raise ArgumentError unless Dcmgr.const_get(class_name) < ServiceType
          @config[:service_types] ||= {}
          @config[:service_types][name] = Dcmgr.const_get(class_name).new(name).parse_dsl(&blk)
          self
        end
      end
      
      # Database connection string
      deprecated_warn_param :database_url
      param :database_uri
      # AMQP broker to be connected.
      param :amqp_server_uri
      
      # UUID for shared host pool or group.
      param :default_shared_host_pool, :default=> 'tag-shhost'

      # UUID for shared network pool or group.
      param :default_shared_network_pool, :default=> 'tag-shnet'

      # UUID for shared storage pool or group.
      param :default_shared_storage_pool, :default=> 'tag-shstor'

      # system wide limit size in MB for creating new volume.
      # (not affect at cloning from snapshot)
      param :create_volume_max_size, :default=>3000
      param :create_volume_min_size, :default=>10

      # Default account quota limit
      param :account_instance_total_weight, :default=>100.0
      param :account_volume_total_size, :default=>100000 # 100GB

      # 1.0 means that 100% of resources are reserved for stopped instances.
      param :stopped_instance_usage_factor, :default=>1.0

      # lists the instances which alives and died within RECENT_TERMED_PERIOD sec.
      param :recent_terminated_instance_period, :default=>900

      # mac address vendor_id
      param :mac_address_vendor_id, :default=>'525400'

      param :default_service_type, :default=>'std'
      
      def validate(errors)
        errors << "database_uri is undefined." unless @config[:database_uri]
        errors << "amqp_server_uri is undefined." unless @config[:amqp_server_uri]
        errors << "default_service_type is undefined." unless @config[:default_service_type]
        errors << "None of service_type is defined." unless @config[:service_types].is_a?(Hash)
        if @config[:mac_address_vendor_id].nil? || @config[:mac_address_vendor_id] !~ /^[\dA-Fa-f]{6}$/
          errors << "Invalid mac_address_vendor_id: #{@config[:mac_address_vendor_id]}"
        end

        unless @config[:create_volume_max_size].is_a?(Integer)
          errors << "create_volume_max_size must be a decimal value: #{@config[:create_volume_max_size]}"
        end
        unless @config[:create_volume_min_size].is_a?(Integer)
          errors << "create_volume_min_size must be a decimal value: #{@config[:create_volume_min_size]}"
        end

        unless @config[:service_types][@config[:default_service_type].to_s]
          errors << "Unable to find the definitions for default_service_type '#{@config[:default_service_type]}'."
        end
      end
    end
  end
end
