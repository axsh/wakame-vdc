# -*- coding: utf-8 -*-

require "fuguta"

module Dcmgr
  module Configurations
    class Hva < Fuguta::Configuration

      class DcNetwork < Fuguta::Configuration
        param :interface
        param :bridge
        param :bridge_type

        def initialize(network_name)
          super()
          @config[:name] = network_name
        end

        def validate(errors)
          errors << "Missing interface parameter for the network #{@config[:name]}" unless @config[:interface]
          errors << "Missing bridge_type parameter for the network #{@config[:name]}" unless @config[:bridge_type]

          case @config[:bridge_type]
          when 'ovs', 'linux'
            # bridge name is needed in this case.
            errors << "Missing bridge parameter for the network #{@config[:name]}" unless @config[:bridge]
          when 'macvlan'
          when 'private'
          else
            errors << "Unknown type value for bridge_type: #{@config[:bridge_type]}"
          end
        end
      end

      class LocalStore < Fuguta::Configuration
        # enable local image cache under "vm_data_dir/_base"
        param :enable_image_caching, :default=>true
        param :image_cache_dir, :default => proc {
          File.expand_path('_base', parent.config[:vm_data_dir])
        }
        param :enable_cache_checksum, :default=>true
        param :max_cached_images, :default=>10
        param :work_dir, :default => proc {
          File.expand_path('tmp', parent.config[:vm_data_dir])
        }
        param :gzip_command, :default=>'gzip'
        param :gunzip_command, :default=>'gunzip'
        param :thread_concurrency, :default=>2

        def validate(errors)
          super
          if !File.directory?(self.work_dir)
            errors << "Unknown directory for work_dir: #{self.work_dir}"
          end

          unless self.thread_concurrency.to_i > 0
            errors << "thread_concurrency needs to set positive integer (> 0): #{self.thread_concurrency}"
          end
        end
      end

      class BackupStorage < Fuguta::Configuration
        param :local_storage_dir, :default => nil

        def validate(errors)
          super
          if @config[:local_storage_dir] && !File.directory?(@config[:local_storage_dir])
            errors << "Unknown directory for local_storage_dir: #{@config[:local_storage_dir]}"
          end
        end
      end

      class Capture < Fuguta::Configuration
        param :cpu_time, :default =>60
        param :memory_time, :default =>60
        param :timeout_sec, :default =>10
        param :retry_count, :default =>1

        def validate(errors)
          super
          unless self.cpu_time.to_i > 0
            errors << "cpu_time needs to set positive integer(>0): #{self.cpu_time}"
          end
          unless self.memory_time.to_i > 0
            errors << "memory_time needs to set positive integer(>0): #{self.memory_time}"
          end
        end
      end

      # Add a parameter to be set to GuestOS startup.
      # For example, if you want to add a host name and ip address to etc hosts.
      #
      # metadata {
      #   path 'extra-hosts/fluent.local', '192.168.1.101'
      # }
      class Metadata < Fuguta::Configuration
        DSL do
          def path(key,value)
            @config[:path_list][key] = value
          end
        end

        def validate(errors)
        end

        def after_initialize
          @config[:path_list] = {}
        end
      end

      def hypervisor_driver(driver_class)
        if driver_class.is_a?(Class) && driver_class < (Drivers::Hypervisor)
          # TODO: do not create here. the configuration object needs to be attached in earlier phase.
          @config[:hypervisor_driver][driver_class] ||= driver_class.configuration_class.new(self)
        elsif (c = Drivers::Hypervisor.driver_class(driver_class))
          # TODO: do not create here. the configuration object needs to be attached in earlier phase.
          @config[:hypervisor_driver][c] ||= c.configuration_class.new(self)
        else
          raise ArgumentError, "Unknown hypervisor driver type: #{driver_class}"
        end
      end

      DSL do
        def dc_network(name, &blk)
          abort "" unless blk

          conf = DcNetwork.new(name)
          @config[:dc_networks][name] = conf.parse_dsl(&blk)
        end

        # local store driver configuration section.
        def local_store(&blk)
          @config[:local_store].parse_dsl(&blk)
        end

        def backup_storage(&blk)
          @config[:backup_storage].parse_dsl(&blk)
        end

        def capture(&blk)
          @config[:capture].parse_dsl(&blk)
        end

        # metadata configuration section.
        def metadata(&blk)
          @config[:metadata].parse_dsl(&blk)
        end

        # hypervisor_driver configuration section.
        def hypervisor_driver(driver_type, &blk)
          c = Drivers::Hypervisor.driver_class(driver_type)
          # Drivers::Hypervisor follows the configuration class hierarchy standard from ConfigrationMethods module.

          conf = Fuguta::Configuration::ConfigurationMethods.find_configuration_class(c).new(self.instance_variable_get(:@subject)).parse_dsl(&blk)
          @config[:hypervisor_driver][c] = conf
        end
      end

      on_initialize_hook do
        @config[:dc_networks] = {}
        @config[:local_store] = LocalStore.new(self)
        @config[:backup_storage] = BackupStorage.new(self)
        @config[:capture] = Capture.new(self)
        @config[:metadata] = Metadata.new(self)
        @config[:hypervisor_driver] = {}
      end

      param :vm_data_dir
      param :enable_iptables, :default=>true
      param :enable_ebtables, :default=>true
      param :hv_ifindex, :default=>2
      param :bridge_novlan, :default=>0
      param :verbose_netfilter, :default=>false
      param :verbose_openflow, :default=>false
      param :verbose_netfilter_cache, :default=>false
      param :packet_drop_log, :default => false
      param :debug_iptables, :default=>false
      param :use_ipset, :default=>false
      param :use_logging_service, :default=>false
      param :logging_service_host_ip, :default =>'127.0.0.2'
      param :logging_service_ip, :default =>'169.254.169.253'
      param :logging_service_port, :default => 8888
      param :logging_service_conf, :default => '/var/lib/wakame-vdc/fluent.conf'
      param :logging_service_reload, :default => '/etc/init.d/td-agent reload'
      param :logging_service_max_read_message_bytes, :default => -1
      param :logging_service_max_match_count, :default => -1
      param :enable_gre, :default=>false
      param :enable_subnet, :default=>false
      param :netfilter_script_post_flush, :default=>nil

      param :brctl_path, :default => '/usr/sbin/brctl'
      param :ovs_run_dir, :default=>'/usr/var/run/openvswitch'
      # Path for ovs-ofctl
      param :ovs_ofctl_path, :default => '/usr/bin/ovs-ofctl'
      # Trema base directory
      param :trema_dir, :default=>'/home/demo/trema'
      param :trema_tmp, :default=> proc {
        @config[:trema_tmp] || (@config[:trema_dir] + '/tmp')
      }

      param :esxi_ipaddress
      param :esxi_datacenter, :default => "ha-datacenter"
      param :esxi_datastore, :default => "datastore1"
      param :esxi_username, :default => "root"
      param :esxi_password, :default => "Some.Password1"
      # Setting this option to true lets you use SSL with untrusted certificates
      param :esxi_insecure, :default => false

      # Decides what kind of edge networking will be used. If omitted, the default 'netfilter' option will be used
      # * 'netfilter'
      # * 'legacy_netfilter' #no longer supported, has issues with multiple vnic vm isolation
      # * 'openflow' #experimental, requires additional setup
      # * 'off'
      param :edge_networking, :default => 'netfilter'

      # If defined, this script will be executed every time netfilter rules are updated
      param :netfilter_hook_script_path, :default => nil

      param :script_root_path, :default => proc {
        File.expand_path('script', DCMGR_ROOT)
      }

      # Allow hva to change instance state seems to be incomplete
      # transition.
      param :enable_instance_state_recovery, :default=>true

      # Dolphin server connection string
      param :dolphin_server_uri, :default=> 'http://127.0.0.1:9004/'

      # Decides what resource monitor will be used.
      param :enabled_feature_resource_monitor, :default=>false

      def validate(errors)
        if @config[:vm_data_dir].nil?
          errors << "vm_data_dir not set"
        elsif !File.exists?(@config[:vm_data_dir])
          errors << "vm_data_dir does not exist: #{@config[:vm_data_dir]}"
        end

        unless ['netfilter', 'legacy_netfilter', 'openflow', 'off'].member?(@config[:edge_networking])
          errors << "Unknown value for edge_networking: #{@config[:edge_networking]}"
        end
      end
    end
  end
end
