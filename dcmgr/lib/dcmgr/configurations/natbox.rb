# -*- coding: utf-8 -*-

require "dcmgr/configurations/features"
require 'fuguta'
require "dcmgr/edge_networking/openflow/ovs_ofctl"

module Dcmgr

  module Configurations

    class Natbox < Features

      usual_paths [
        ENV['CONF_PATH'].to_s,
        '/etc/wakame-vdc/natbox.conf',
        File.expand_path('config/natbox.conf', ::Dcmgr::DCMGR_ROOT)
      ]

      class DcNetwork < Fuguta::Configuration
        param :interface
        param :bridge

        def initialize(network_name)
          super()
          @config[:name] = network_name
        end

        def validate(errors)
          errors << "Missing interface parameter for the network #{@config[:name]}" unless @config[:interface]
          errors << "Missing bridge parameter for the network #{@config[:name]}" unless @config[:bridge]
        end
      end

      DSL do
        def outside_dc_network(name, &blk)
          abort "" unless blk
          conf = DcNetwork.new(name)
          @config[:outside_dc_network] = conf.parse_dsl(&blk)
        end

        def inside_dc_network(name, &blk)
          abort "" unless blk
          conf = DcNetwork.new(name)
          @config[:inside_dc_network] = conf.parse_dsl(&blk)
        end

        # backward compatiblility
        def ovs_ofctl_path(v)
          @config[:ovs_ofctl].config[:ovs_ofctl_path] = v
        end
        alias_method :ovs_ofctl_path=, :ovs_ofctl_path

        def verbose_openflow(v)
          @config[:ovs_ofctl].config[:verbose_openflow] = v
        end
        alias_method :verbose_openflow=, :verbose_openflow
      end

      param :ovs_flow_table, :default => 0
      param :ovs_flow_priority, :default => 100

      def validate(errors)
        [:outside_dc_network, :inside_dc_network].each do |dc_network|
          errors << "Missing #{dc_network} parameter" unless @config[dc_network]
        end
      end

      def after_initialize
        super
        @config[:ovs_ofctl] = EdgeNetworking::OpenFlow::OvsOfctl::Configuration.new(self)
      end
    end

  end

end
