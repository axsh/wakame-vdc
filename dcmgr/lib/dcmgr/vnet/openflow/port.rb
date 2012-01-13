# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module OpenFlow

      class OpenFlowPort
        include OpenFlowConstants

        attr_reader :datapath
        attr_reader :port_info
        attr_reader :lock
        attr_reader :port_type

        attr_accessor :has_instance
        attr_accessor :is_active
        attr_accessor :ip
        attr_accessor :mac
        attr_accessor :network

        def initialize dp, port_info
          @datapath = dp
          @port_info = port_info
          @lock = Mutex.new
          @port_type = PORT_TYPE_NONE

          @has_instance = false
          @is_active = false
        end

        def init_eth
          @port_type = PORT_TYPE_ETH
          queue_flow_2 Flow.new(0, 6, {:udp => nil, :in_port => OpenFlowController::OFPP_LOCAL, :dl_dst => 'ff:ff:ff:ff:ff:ff', :nw_src => '0.0.0.0', :nw_dst => '255.255.255.255', :tp_src => 68, :tp_dst => 67}, {:output => port_info.number})
          queue_flow_2 Flow.new(0, 2, {:in_port => port_info.number},  {:resubmit => TABLE_ROUTE_DIRECTLY})
          queue_flow_2 Flow.new(TABLE_MAC_ROUTE, 0, {}, {:output => port_info.number})
          queue_flow_2 Flow.new(TABLE_ROUTE_DIRECTLY, 0, {}, {:output => port_info.number})
          queue_flow_2 Flow.new(TABLE_LOAD_DST, 0, {}, [{:load_reg0 => port_info.number}, {:resubmit => TABLE_LOAD_SRC}])
          queue_flow_2 Flow.new(TABLE_LOAD_SRC, 4, {:in_port => port_info.number}, {:output_reg0 => nil})
          queue_flow_2 Flow.new(TABLE_ARP_ANTISPOOF, 1, {:arp => nil, :in_port => port_info.number}, {:resubmit => TABLE_ARP_ROUTE})
          queue_flow_2 Flow.new(TABLE_ARP_ROUTE, 0, {:arp => nil}, {:output => port_info.number})
          queue_flow_2 Flow.new(TABLE_METADATA_OUTGOING, 4, {:in_port => port_info.number}, {:drop => nil})
        end

        def init_gre_tunnel
          @port_type = PORT_TYPE_TUNNEL
          queue_flow "priority=#{7}", "table=#{0},in_port=#{port_info.number}", "load:#{network.id}->NXM_NX_REG1[],load:#{port_info.number}->NXM_NX_REG2[],resubmit(,#{TABLE_VIRTUAL_SRC})"
        end

        def init_instance_net hw, ip
          @port_type = PORT_TYPE_INSTANCE_NET
          queue_flow "priority=#{1}", "table=#{TABLE_MAC_ROUTE},dl_dst=#{hw}", "output:#{port_info.number}"
          queue_flow "priority=#{2}", "table=#{0},in_port=#{port_info.number},dl_src=#{hw}", "resubmit(,#{TABLE_ROUTE_DIRECTLY})"
          queue_flow "priority=#{1}", "table=#{TABLE_ROUTE_DIRECTLY},dl_dst=#{hw}", "output:#{port_info.number}"
          queue_flow "priority=#{1}", "table=#{TABLE_LOAD_DST},dl_dst=#{hw}", "drop"
        end

        def init_instance_vnet hw, ip
          @port_type = PORT_TYPE_INSTANCE_VNET

          queue_flow "priority=#{7}", "table=#{0},in_port=#{port_info.number}", "load:#{network.id}->NXM_NX_REG1[],resubmit(,#{TABLE_VIRTUAL_SRC})"
          queue_flow "priority=#{2}", "table=#{TABLE_VIRTUAL_DST},reg1=#{network.id},dl_dst=#{hw}", "output:#{port_info.number}"
        end

        def install_arp_antispoof hw, ip
          # Require correct ARP source IP/MAC from instance, and protect the instance IP from ARP spoofing.
          queue_flow "priority=#{3}", "table=#{TABLE_ARP_ANTISPOOF},arp,in_port=#{port_info.number},arp_sha=#{hw},nw_src=#{ip}", "resubmit(,#{TABLE_ARP_ROUTE})"
          queue_flow "priority=#{2}", "table=#{TABLE_ARP_ANTISPOOF},arp,arp_sha=#{hw}", "drop"
          queue_flow "priority=#{2}", "table=#{TABLE_ARP_ANTISPOOF},arp,nw_src=#{ip}", "drop"

          # Routing of ARP packets to instance.
          queue_flow "priority=#{2}", "table=#{TABLE_ARP_ROUTE},arp,dl_dst=#{hw},nw_dst=#{ip}", "output:#{port_info.number}"
        end

        def install_static_transport nw_proto, local_hw, local_ip, local_port, remote_ip
          match_type = "dl_type=0x0800,nw_proto=#{nw_proto}"

          src_match = ""
          src_match << ",nw_src=#{remote_ip}" if not remote_ip =~ /\/0$/
          src_match << ",tp_dst=#{local_port}" if local_port != 0
          dst_match = ""
          dst_match << ",nw_dst=#{remote_ip}" if not remote_ip =~ /\/0$/
          dst_match << ",tp_src=#{local_port}" if local_port != 0

          incoming_match = "table=#{TABLE_LOAD_DST},#{match_type},dl_dst=#{local_hw},nw_dst=#{local_ip}#{src_match}"
          incoming_actions = "load:#{port_info.number}->NXM_NX_REG0[],resubmit(,#{TABLE_LOAD_SRC})"
          queue_flow "priority=#{3}", incoming_match, incoming_actions

          outgoing_match = "table=#{TABLE_LOAD_SRC},#{match_type},in_port=#{port_info.number},dl_src=#{local_hw},nw_src=#{local_ip}#{dst_match}"
          outgoing_actions = "output:NXM_NX_REG0[]"
          queue_flow "priority=#{3}", outgoing_match, outgoing_actions
        end

        def install_static_d_transport nw_proto, local_hw, local_ip, remote_ip, remote_port
          match_type = "dl_type=0x0800,nw_proto=#{nw_proto}"

          src_match = ""
          src_match << ",nw_src=#{remote_ip}" if not remote_ip =~ /\/0$/
          src_match << ",tp_src=#{remote_port}" if remote_port != 0
          dst_match = ""
          dst_match << ",nw_dst=#{remote_ip}" if not remote_ip =~ /\/0$/
          dst_match << ",tp_dst=#{remote_port}" if remote_port != 0

          incoming_match = "table=#{TABLE_LOAD_DST},#{match_type},dl_dst=#{local_hw},nw_dst=#{local_ip}#{src_match}"
          incoming_actions = "load:#{port_info.number}->NXM_NX_REG0[],resubmit(,#{TABLE_LOAD_SRC})"
          queue_flow "priority=#{3}", incoming_match, incoming_actions

          outgoing_match = "table=#{TABLE_LOAD_SRC},#{match_type},in_port=#{port_info.number},dl_src=#{local_hw},nw_src=#{local_ip}#{dst_match}"
          outgoing_actions = "output:NXM_NX_REG0[]"
          queue_flow "priority=#{3}", outgoing_match, outgoing_actions
        end

        def install_static_icmp icmp_type, icmp_code, local_hw, local_ip, src_ip
          match_type = "dl_type=0x0800,nw_proto=1"
          match_type << ",icmp_type=#{icmp_type}" if icmp_type >= 0
          match_type << ",icmp_code=#{icmp_code}" if icmp_code >= 0

          src_ip_match = ""
          src_ip_match << ",nw_src=#{src_ip}" if not src_ip =~ /\/0$/

          incoming_match = "table=#{TABLE_LOAD_DST},#{match_type},dl_dst=#{local_hw},nw_dst=#{local_ip}#{src_ip_match}"
          incoming_actions = "load:#{port_info.number}->NXM_NX_REG0[],resubmit(,#{TABLE_LOAD_SRC})"
          queue_flow "priority=#{3}", incoming_match, incoming_actions

          outgoing_match = "table=#{TABLE_LOAD_SRC},#{match_type},in_port=#{port_info.number},dl_src=#{local_hw},nw_src=#{local_ip}#{src_ip_match},"
          outgoing_actions = "output:NXM_NX_REG0[]"
          queue_flow "priority=#{3}", outgoing_match, outgoing_actions
        end

        def install_local_icmp hw, ip
          match_type = "dl_type=0x0800,nw_proto=1"

          learn_outgoing_match = "priority=#{2},idle_timeout=#{60},table=#{TABLE_LOAD_DST},#{match_type},NXM_OF_IN_PORT[],NXM_OF_ETH_SRC[],NXM_OF_ETH_DST[],NXM_OF_IP_SRC[],NXM_OF_IP_DST[]"
          learn_outgoing_actions = "output:NXM_NX_REG0[]"

          learn_incoming_match = "priority=#{2},idle_timeout=#{60},table=#{TABLE_LOAD_DST},#{match_type},NXM_OF_IN_PORT[]=NXM_NX_REG0[0..15],NXM_OF_ETH_SRC[]=NXM_OF_ETH_DST[],NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[],NXM_OF_IP_SRC[]=NXM_OF_IP_DST[],NXM_OF_IP_DST[]=NXM_OF_IP_SRC[]"
          learn_incoming_actions = "output:NXM_OF_IN_PORT[]"

          actions = "learn(#{learn_outgoing_match},#{learn_outgoing_actions}),learn(#{learn_incoming_match},#{learn_incoming_actions}),output:NXM_NX_REG0[]"

          queue_flow "priority=#{1}", "table=#{TABLE_LOAD_SRC},#{match_type},in_port=#{port_info.number},dl_src=#{hw},nw_src=#{ip}", actions
        end

        def install_local_transport nw_proto, hw, ip
          case nw_proto
          when 6
            transport_name = "TCP"
            idle_timeout = 7200
          when 17
            transport_name = "UDP"
            idle_timeout = 600
          end

          match_type = "dl_type=0x0800,nw_proto=#{nw_proto}"

          learn_outgoing_match = "priority=#{2},idle_timeout=#{idle_timeout},table=#{TABLE_LOAD_DST},#{match_type},NXM_OF_IN_PORT[],NXM_OF_ETH_SRC[],NXM_OF_ETH_DST[],NXM_OF_IP_SRC[],NXM_OF_IP_DST[],NXM_OF_#{transport_name}_SRC[],NXM_OF_#{transport_name}_DST[]"
          learn_outgoing_actions = "output:NXM_NX_REG0[]"

          learn_incoming_match = "priority=#{2},idle_timeout=#{idle_timeout},table=#{TABLE_LOAD_DST},#{match_type},NXM_OF_IN_PORT[]=NXM_NX_REG0[0..15],NXM_OF_ETH_SRC[]=NXM_OF_ETH_DST[],NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[],NXM_OF_IP_SRC[]=NXM_OF_IP_DST[],NXM_OF_IP_DST[]=NXM_OF_IP_SRC[],NXM_OF_#{transport_name}_SRC[]=NXM_OF_#{transport_name}_DST[],NXM_OF_#{transport_name}_DST[]=NXM_OF_#{transport_name}_SRC[]"
          learn_incoming_actions = "output:NXM_OF_IN_PORT[]"

          actions = "learn(#{learn_outgoing_match},#{learn_outgoing_actions}),learn(#{learn_incoming_match},#{learn_incoming_actions}),output:NXM_NX_REG0[]"

          queue_flow "priority=#{1}", "table=#{TABLE_LOAD_SRC},#{match_type},in_port=#{port_info.number},dl_src=#{hw},nw_src=#{ip}", actions
        end

        def active_flows
          @active_flows ||= Array.new
        end

        def queued_flows
          @queued_flows ||= Array.new
        end

        def queue_flow prefix, match, actions
          active_flows << match
          queued_flows << ["#{prefix},#{match}", actions]
        end

        def queue_flow_2 flow
          active_flows << flow.match_to_s
          queued_flows << [flow.match_to_s, flow.actions_to_s]
        end

      end

    end
  end
end
