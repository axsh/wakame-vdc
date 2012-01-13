# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module OpenFlow

      class OpenFlowNetwork
        include OpenFlowConstants

        attr_reader :id
        attr_reader :datapath

        # Add _numbers postfix.
        attr_reader :ports
        attr_reader :local_ports

        attr_accessor :virtual
        attr_accessor :dhcp_hw
        attr_accessor :dhcp_ip
        attr_accessor :ipv4_network
        attr_accessor :prefix

        def initialize dp, id
          @id = id
          @datapath = dp
          @ports = []
          @local_ports = []

          @virtual = false
          @prefix = 0
        end

        def update
          datapath.ovs_ofctl.add_flows_from_list generate_flood_flows
        end

        def add_port port, is_local
          ports << port
          local_ports << port if is_local
        end

        def remove_port port
          ports.delete port
          local_ports.delete port
        end

        def generate_flood_flows
          flows = []
          flood_flows.each { |flow|
            flows << [flow[0], "#{flow[1]}#{generate_flood_actions(flow[2], ports)}#{flow[3]}"]
          }
          flood_local_flows.each { |flow|
            flows << [flow[0], "#{flow[1]}#{generate_flood_actions(flow[2], local_ports)}#{flow[3]}"]
          }
          flows
        end

        def generate_flood_actions template, use_ports
          actions = ""
          use_ports.each { |port|
            actions << ",#{template.gsub('<>', port.to_s)}"
          }
          actions
        end

        def flood_flows
          @flood_flows ||= Array.new
        end

        def flood_local_flows
          @flood_local_flows ||= Array.new
        end

        def install_virtual_network
          flood_flows       << ["priority=#{1},table=#{TABLE_VIRTUAL_DST},reg1=#{id},reg2=#{0},dl_dst=ff:ff:ff:ff:ff:ff", "", "output:<>", ""]
          flood_local_flows << ["priority=#{0},table=#{TABLE_VIRTUAL_DST},reg1=#{id},dl_dst=ff:ff:ff:ff:ff:ff", "", "output:<>", ""]

          learn_arp_match = "priority=#{1},idle_timeout=#{3600*10},table=#{TABLE_VIRTUAL_DST},reg1=#{id},reg2=#{0},NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]"
          learn_arp_actions = "output:NXM_NX_REG2[]"

          flows = []

          # Pass packets to the dst table if it originates from an instance on this host. (reg2 == 0)
          flows << Flow.new(TABLE_VIRTUAL_SRC, 2, {:reg1 => id, :reg2 => 0}, {:resubmit => TABLE_VIRTUAL_DST})
          # If from an external host, learn the ARP for future use.
          flows << Flow.new(TABLE_VIRTUAL_SRC, 1, {:reg1 => id, :arp => nil}, [{:learn => "#{learn_arp_match},#{learn_arp_actions}"}, {:resubmit => TABLE_VIRTUAL_DST}])
          # Default action is to pass the packet to the dst table.
          flows << Flow.new(TABLE_VIRTUAL_SRC, 0, {:reg1 => id}, {:resubmit => TABLE_VIRTUAL_DST})

          # Catch ARP for the DHCP server.
          flows << Flow.new(TABLE_VIRTUAL_DST, 3, {:reg1 => id, :arp => nil, :nw_dst => dhcp_ip.to_s}, {:controller => nil})

          # Catch DHCP requests.
          flows << Flow.new(TABLE_VIRTUAL_DST, 3, {:reg1 => id, :udp => nil, :dl_dst => dhcp_hw, :nw_dst => dhcp_ip.to_s, :tp_src => 68, :tp_dst => 67}, {:controller => nil})
          flows << Flow.new(TABLE_VIRTUAL_DST, 3, {:reg1 => id, :udp => nil, :dl_dst => 'ff:ff:ff:ff:ff:ff', :nw_dst => '255.255.255.255', :tp_src => 68, :tp_dst => 67}, {:controller => nil})

          datapath.add_flows flows
        end

        def install_physical_network
          flood_flows << ["priority=#{1},table=#{TABLE_MAC_ROUTE},dl_dst=FF:FF:FF:FF:FF:FF", "", "output:<>", ""]
          flood_flows << ["priority=#{1},table=#{TABLE_ROUTE_DIRECTLY},dl_dst=FF:FF:FF:FF:FF:FF", "", "output:<>", ""]
          flood_flows << ["priority=#{1},table=#{TABLE_LOAD_DST},dl_dst=FF:FF:FF:FF:FF:FF", "", "load:<>->NXM_NX_REG0[],resubmit(,#{TABLE_LOAD_SRC})", ""]
          flood_flows << ["priority=#{1},table=#{TABLE_ARP_ROUTE},arp,dl_dst=FF:FF:FF:FF:FF:FF,arp_tha=00:00:00:00:00:00", "", "output:<>", ""]
        end

      end

    end
  end
end
