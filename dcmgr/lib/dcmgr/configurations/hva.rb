# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    class Hva < Configuration
      
      class DcNetwork < Configuration
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

      class LocalStore < Configuration
        # enable local image cache under "vm_data_dir/_base"
        param :enable_image_caching, :default=>true
        param :image_cache_dir, :default => proc {
          File.expand_path('_base', @config[:vm_data_dir])
        }
        param :enable_cache_checksum, :default=>true
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
      end

      on_initialize_hook do
        @config[:dc_networks] = {}
        @config[:local_store] = LocalStore.new
      end

      param :vm_data_dir
      param :enable_iptables, :default=>true
      param :enable_ebtables, :default=>true
      param :hv_ifindex, :default=>2
      param :bridge_novlan, :default=>0
      param :verbose_netfilter, :default=>false
      param :verbose_openflow, :default=>false
      param :packet_drop_log, :default => false
      param :debug_iptables, :default=>false
      param :use_ipset, :default=>false
      param :enable_gre, :default=>false
      param :enable_subnet, :default=>false

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

      param :script_root_path, :default => proc {
        File.expand_path('script', DCMGR_ROOT)
      }
      
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
