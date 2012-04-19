# -*- coding: utf-8 -*-

module Dcmgr
  module Configurations
    class Hva < Configuration
      
      class Interface < Configuration
        param :network
        param :bridge

        def initialize(interface_name)
          super()
          @config[:interface] = interface_name
        end
        
        def validate(errors)
          errors << "Missing network parameter" unless @config.has_key?(:network)
          errors << "Missing bridge parameter" unless @config.has_key?(:bridge)
        end
      end
      
      module DSL
        def interface(name, &blk)
          abort "" unless blk
          
          conf = Interface.new(name)
          @config[:interface] ||= {}
          @config[:interface][name] = conf.parse_dsl(&blk)
        end
      end

      param :vm_data_dir
      param :edge_networking, :default=>'netfilter'
      param :enable_iptables, :default=>true
      param :enable_ebtables, :default=>true
      param :hv_ifindex, :default=>2
      param :bridge_novlan, :default=>0
      param :verbose_netfilter, :default=>false
      param :packet_drop_log, :default => false
      param :debug_iptables, :default=>false
      param :use_ipset, :default=>false
      param :enable_gre, :default=>false
      param :enable_subnet, :default=>false
      
      def validate(errors)
        errors << "vm_data_dir" unless @config.has_key?(:vm_data_dir)
        unless File.exists?(@config[:vm_data_dir])
          errors << "vm_data_dir does not exist: #{@config[:vm_data_dir]}"
        end
      end
    end
  end
end
