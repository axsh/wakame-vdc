# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module OpenFlow

      class OpenFlowNetwork
        include Dcmgr::Logger
        include OpenFlowConstants

        attr_reader :id
        attr_reader :datapath

        # Add _numbers postfix.
        attr_reader :ports
        attr_reader :local_ports

        # Use the actual network db object instead.
        attr_accessor :virtual
        attr_accessor :domain_name
        attr_accessor :local_hw
        attr_accessor :dhcp_hw
        attr_accessor :dhcp_ip
        # Can cause issues if dns_ip is not the same as dhcp_ip.
        attr_accessor :dns_ip
        attr_accessor :ipv4_network
        attr_accessor :ipv4_gw
        attr_accessor :prefix

        attr_accessor :metadata_server_ip
        attr_accessor :metadata_server_mac
        attr_accessor :metadata_server_port
        attr_accessor :metadata_server_output

        def initialize dp, id
          @id = id
          @datapath = dp
          @ports = []
          @local_ports = []

          @virtual = false
          @prefix = 0
        end

        def update
          datapath.add_flood_flows(flood_flows, ports)
          datapath.add_flood_flows(flood_local_flows, local_ports)
        end

        def add_port port, is_local
          ports << port
          local_ports << port if is_local
        end

        def remove_port port
          ports.delete port
          local_ports.delete port
        end

        def flood_flows
          @flood_flows ||= Array.new
        end

        def flood_local_flows
          @flood_local_flows ||= Array.new
        end

        def install_virtual_network
          flood_flows       << Flow.new(TABLE_VIRTUAL_DST, 1, {:reg1 => id, :reg2 => 0, :dl_dst => 'ff:ff:ff:ff:ff:ff'}, {:output => FlowPlaceholder.new(0)})
          flood_local_flows << Flow.new(TABLE_VIRTUAL_DST, 0, {:reg1 => id, :dl_dst => 'ff:ff:ff:ff:ff:ff'}, {:output => FlowPlaceholder.new(0)})

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
          flood_flows << Flow.new(TABLE_MAC_ROUTE,      1, {:dl_dst => 'FF:FF:FF:FF:FF:FF'}, {:output => FlowPlaceholder.new(0)})
          flood_flows << Flow.new(TABLE_ROUTE_DIRECTLY, 1, {:dl_dst => 'FF:FF:FF:FF:FF:FF'}, {:output => FlowPlaceholder.new(0)})
          flood_flows << Flow.new(TABLE_LOAD_DST,       1, {:dl_dst => 'FF:FF:FF:FF:FF:FF'}, [{:load_reg0 => FlowPlaceholder.new(0)}, {:resubmit => TABLE_LOAD_SRC}])
          flood_flows << Flow.new(TABLE_ARP_ROUTE,      1, {:arp => nil, :dl_dst => 'FF:FF:FF:FF:FF:FF', :arp_tha => '00:00:00:00:00:00'}, {:output => FlowPlaceholder.new(0)})
        end

        def request_metadata_server_mac port
          logger.info "Requesting metadata server mac: port:#{port} ip:#{metadata_server_ip.to_s}/#{metadata_server_port}."

          # Add timeout? Or clean up manually.
          flows = [Flow.new(TABLE_ARP_ROUTE, 3, {
                              :in_port => port, :arp => nil,
                              :dl_dst => local_hw, :nw_dst => Isono::Util.default_gw_ipaddr,
                              :nw_src => metadata_server_ip.to_s},
                            {:controller => nil})]

          datapath.add_flows flows        
          datapath.send_arp(port, Racket::L3::ARP::ARPOP_REQUEST,
                            local_hw.to_s,
                            Isono::Util.default_gw_ipaddr.to_s,
                            nil,
                            metadata_server_ip.to_s)
        end

        def install_metadata_server port, dest_hw
          @metadata_server_output = port
          @metadata_server_mac = dest_hw

          logger.info "Adding metadata server: port:#{@metadata_server_output} mac:#{@metadata_server_mac.to_s} ip:#{metadata_server_ip.to_s}/#{metadata_server_port}."

          flows = []

          # Currently only add for the physical networks.
          flows << Flow.new(TABLE_CLASSIFIER, 5, {:tcp => nil, :nw_dst => '169.254.169.254', :tp_dst => 80}, {:resubmit => TABLE_METADATA_OUTGOING})
          flows << Flow.new(TABLE_CLASSIFIER, 5, {:tcp => nil, :nw_src => metadata_server_ip.to_s, :tp_src => metadata_server_port}, {:resubmit => TABLE_METADATA_INCOMING})

          # Replace with dnat entries instead of custom tables.
          #flows << Flow.new(TABLE_METADATA_OUTGOING, 0, {}, {:drop => nil})
          flows << Flow.new(TABLE_METADATA_OUTGOING, 1, {}, {:controller => nil})

          datapath.add_flows flows        
        end

      end

    end
  end
end
