# -*- coding: utf-8 -*-

module Dcmgr
  
  module Configurations

    class Natbox < Configuration

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
          when 'ovs'
            # bridge name is needed in this case.
            errors << "Missing bridge parameter for the network #{@config[:name]}" unless @config[:bridge]
          when 'linux'
          when 'macvlan'
          when 'private'
          else
            errors << "Unknown type value for bridge_type: #{@config[:bridge_type]}"
          end
        end
      end

      DSL do
        def dc_network(name, &blk)
          abort "" unless blk

          conf = DcNetwork.new(name)
          @config[:dc_networks][name] = conf.parse_dsl(&blk)
        end
      end

      on_initialize_hook do
        @config[:dc_networks] = {}
      end

      param :ovs_ofctl_path, :default => "/usr/bin/ovs-ofctl"
      param :verbose_openflow, :default => false
      param :ovs_flow_table, :default => 0
      param :ovs_flow_priority, :default => 100

      def validate(errors)
      end

    end

  end

end
