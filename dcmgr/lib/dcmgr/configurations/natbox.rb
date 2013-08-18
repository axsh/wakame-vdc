# -*- coding: utf-8 -*-

require 'fuguta'

module Dcmgr
  
  module Configurations

    class Natbox < Fuguta::Configuration

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
      end

      param :ovs_ofctl_path, :default => "/usr/bin/ovs-ofctl"
      param :verbose_openflow, :default => false
      param :ovs_flow_table, :default => 0
      param :ovs_flow_priority, :default => 100

      def validate(errors)
        [:outside_dc_network, :inside_dc_network].each do |dc_network|
          errors << "Missing #{dc_network} parameter" unless @config[dc_network]
        end
      end

    end

  end

end
