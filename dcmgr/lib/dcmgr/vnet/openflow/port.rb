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
        attr_accessor :is_inserted
        attr_accessor :ip
        attr_accessor :mac
        attr_accessor :networks

        def initialize dp, port_info
          @datapath = dp
          @port_info = port_info
          @lock = Mutex.new
          @port_type = PORT_TYPE_NONE

          @has_instance = false
          @is_active = false
          @is_inserted = false
          @networks = []
        end

        def inspect
          str = "<"
          str << "@port_info=#{@port_info.inspect}, "
          str << "@port_type=#{@port_type.inspect}, "
          str << "@has_instance=#{@has_instance.inspect}, "
          str << "@is_active=#{@is_active.inspect}, "
          str << "@is_inserted=#{@is_inserted.inspect}>"
          str
        end

        def init_eth
          @port_type = PORT_TYPE_ETH
          queue_flow Flow.new(TABLE_CLASSIFIER, 6, {:udp => nil, :in_port => OpenFlowController::OFPP_LOCAL,
                                :dl_dst => 'ff:ff:ff:ff:ff:ff', :nw_src => '0.0.0.0', :nw_dst => '255.255.255.255', :tp_src => 68, :tp_dst => 67},
                              {:output => port_info.number})
          queue_flow Flow.new(TABLE_CLASSIFIER, 5, {:udp => nil, :in_port => port_info.number,
                                :dl_dst => 'ff:ff:ff:ff:ff:ff', :nw_src => '0.0.0.0', :nw_dst => '255.255.255.255', :tp_src => 68, :tp_dst =>67},
                              {:local => nil})
          queue_flow Flow.new(TABLE_CLASSIFIER,     2, {:in_port => port_info.number},  {:resubmit => TABLE_ROUTE_DIRECTLY})
          queue_flow Flow.new(TABLE_MAC_ROUTE,      0, {}, {:output => port_info.number})
          queue_flow Flow.new(TABLE_ROUTE_DIRECTLY, 0, {}, {:output => port_info.number})
          queue_flow Flow.new(TABLE_LOAD_DST,       0, {}, [{:load_reg0 => port_info.number}, {:resubmit => TABLE_LOAD_SRC}])
          queue_flow Flow.new(TABLE_LOAD_SRC,       4, {:in_port => port_info.number}, {:output_reg0 => nil})
          queue_flow Flow.new(TABLE_ARP_ANTISPOOF,  1, {:arp => nil, :in_port => port_info.number}, {:resubmit => TABLE_ARP_ROUTE})
          queue_flow Flow.new(TABLE_ARP_ROUTE,      0, {:arp => nil}, {:output => port_info.number})

          queue_flow Flow.new(TABLE_METADATA_INCOMING, 2, {:in_port => OpenFlowController::OFPP_LOCAL}, {:output => port_info.number})
          queue_flow Flow.new(TABLE_METADATA_OUTGOING, 4, {:in_port => port_info.number}, {:local => nil})
        end

        def init_gre_tunnel(network)
          @port_type = PORT_TYPE_TUNNEL
          queue_flow Flow.new(TABLE_CLASSIFIER, 8, {:in_port => port_info.number}, [{:load_reg1 => network.id, :load_reg2 => port_info.number}, {:resubmit => TABLE_VIRTUAL_SRC}])
        end

        def init_instance_net(network, hw, ip)
          @port_type = PORT_TYPE_INSTANCE_NET
          queue_flow Flow.new(TABLE_MAC_ROUTE,      1, {:dl_dst => hw}, {:output => port_info.number})
          queue_flow Flow.new(TABLE_CLASSIFIER,     2, {:in_port => port_info.number, :dl_src => hw}, {:resubmit => TABLE_ROUTE_DIRECTLY})
          queue_flow Flow.new(TABLE_ROUTE_DIRECTLY, 1, {:dl_dst => hw}, {:output => port_info.number})
          queue_flow Flow.new(TABLE_LOAD_DST,       1, {:dl_dst => hw}, {:drop => nil})
        end

        def init_instance_vnet(network, hw, ip)
          @port_type = PORT_TYPE_INSTANCE_VNET
          queue_flow Flow.new(TABLE_CLASSIFIER,  8, {:in_port => port_info.number}, {:load_reg1 => network.id, :resubmit => TABLE_VIRTUAL_SRC})
          # TABLE_VIRTUAL_SRC-4 reg1=network.id,reg2=0x0 actions=drop
          queue_flow Flow.new(TABLE_VIRTUAL_SRC, 5, {:in_port => port_info.number, :ip => nil, :dl_src => hw, :nw_src => ip}, {:resubmit => TABLE_VIRTUAL_DST})
          queue_flow Flow.new(TABLE_VIRTUAL_SRC, 5, {:in_port => port_info.number, :ip => nil, :dl_src => hw, :nw_src => '0.0.0.0'}, {:resubmit => TABLE_VIRTUAL_DST})
          queue_flow Flow.new(TABLE_VIRTUAL_SRC, 9, {:in_port => port_info.number, :arp => nil, :dl_src => hw, :nw_src => ip, :arp_sha => hw}, {:resubmit => TABLE_VIRTUAL_DST})
          queue_flow Flow.new(TABLE_VIRTUAL_DST, 2, {:reg1 => network.id, :dl_dst => hw}, {:output => port_info.number})
        end

        def init_instance_subnet(network, eth_port, hw, ip)
          queue_flow Flow.new(TABLE_CLASSIFIER, 8, {:in_port => eth_port, :dl_dst => hw}, {:load_reg1 => network.id, :load_reg2 => eth_port, :resubmit => TABLE_VIRTUAL_SRC})
        end

        # Install flows:

        def install_catch_ip nw_proto, match
          match[:in_port] = port_info.number
          match[:dl_type] = 0x0800
          match[:nw_proto] = nw_proto
          queue_flow Flow.new(TABLE_LOAD_DST, 3, match, {:controller => nil})
        end

        def install_static_d_transport nw_proto, local_hw, local_ip, remote_ip, remote_port
          src_match = {:dl_type => 0x0800, :nw_proto => nw_proto}
          src_match[:nw_src] = remote_ip if not remote_ip =~ /\/0$/
          src_match[:tp_src] = remote_port if remote_port != 0

          incoming_match = {:dl_dst => local_hw, :nw_dst => local_ip}.merge(src_match)
          queue_flow Flow.new(TABLE_LOAD_DST, 3, incoming_match, [{:load_reg0 => port_info.number}, {:resubmit => TABLE_LOAD_SRC}])

          dst_match = {:dl_type => 0x0800, :nw_proto => nw_proto}
          dst_match[:nw_dst] = remote_ip if not remote_ip =~ /\/0$/
          dst_match[:tp_dst] = remote_port if remote_port != 0

          outgoing_match = {:in_port => port_info.number, :dl_src => local_hw, :nw_src => local_ip}.merge(dst_match)
          queue_flow Flow.new(TABLE_LOAD_SRC, 3, outgoing_match, {:output_reg0 => nil})
        end


        def install_arp_antispoof hw, ip
          # Require correct ARP source IP/MAC from instance, and protect the instance IP from ARP spoofing.
          queue_flow Flow.new(TABLE_ARP_ANTISPOOF, 3, {:arp => nil, :in_port => port_info.number, :arp_sha => hw, :nw_src => ip}, {:resubmit => TABLE_ARP_ROUTE})
          queue_flow Flow.new(TABLE_ARP_ANTISPOOF, 2, {:arp => nil, :arp_sha => hw}, {:drop => nil})
          queue_flow Flow.new(TABLE_ARP_ANTISPOOF, 2, {:arp => nil, :nw_src => ip}, {:drop => nil})

          # Routing of ARP packets to instance.
          queue_flow Flow.new(TABLE_ARP_ROUTE, 2, {:arp => nil, :dl_dst => hw, :nw_dst => ip}, {:output => port_info.number})
        end

        def install_static_transport nw_proto, local_hw, local_ip, local_port, remote_ip
          src_match = {:dl_type => 0x0800, :nw_proto => nw_proto}
          src_match[:nw_src] = remote_ip if not remote_ip =~ /\/0$/
          src_match[:tp_dst] = local_port if local_port != 0

          incoming_match = {:dl_dst => local_hw, :nw_dst => local_ip}.merge(src_match)
          queue_flow Flow.new(TABLE_LOAD_DST, 3, incoming_match, [{:load_reg0 => port_info.number}, {:resubmit => TABLE_LOAD_SRC}])

          dst_match = {:dl_type => '0x0800', :nw_proto => nw_proto}
          dst_match[:nw_dst] = remote_ip if not remote_ip =~ /\/0$/
          dst_match[:tp_src] = local_port if local_port != 0

          outgoing_match = {:in_port => port_info.number, :dl_src => local_hw, :nw_src => local_ip}.merge(dst_match)
          queue_flow Flow.new(TABLE_LOAD_SRC, 3, outgoing_match, {:output_reg0 => nil})
        end

        def install_static_d_transport nw_proto, local_hw, local_ip, remote_ip, remote_port
          src_match = {:dl_type => 0x0800, :nw_proto => nw_proto}
          src_match[:nw_src] = remote_ip if not remote_ip =~ /\/0$/
          src_match[:tp_src] = remote_port if remote_port != 0

          incoming_match = {:dl_dst => local_hw, :nw_dst => local_ip}.merge(src_match)
          queue_flow Flow.new(TABLE_LOAD_DST, 3, incoming_match, [{:load_reg0 => port_info.number}, {:resubmit => TABLE_LOAD_SRC}])

          dst_match = {:dl_type => 0x0800, :nw_proto => nw_proto}
          dst_match[:nw_dst] = remote_ip if not remote_ip =~ /\/0$/
          dst_match[:tp_dst] = remote_port if remote_port != 0

          outgoing_match = {:in_port => port_info.number, :dl_src => local_hw, :nw_src => local_ip}.merge(dst_match)
          queue_flow Flow.new(TABLE_LOAD_SRC, 3, outgoing_match, {:output_reg0 => nil})
        end

        def install_static_icmp icmp_type, icmp_code, local_hw, local_ip, src_ip
          match_type = {:dl_type => 0x0800, :nw_proto => 1}
          match_type[:icmp_type] = icmp_type if icmp_type >= 0
          match_type[:icmp_code] = icmp_code if icmp_code >= 0

          incoming_match = {:dl_dst => local_hw, :nw_dst => local_ip}.merge(match_type)
          incoming_match[:nw_src] = src_ip unless src_ip =~ /\/0$/
          queue_flow Flow.new(TABLE_LOAD_DST, 3, incoming_match, [{:load_reg0 => port_info.number}, {:resubmit => TABLE_LOAD_SRC}])

          outgoing_match = {:in_port => port_info.number, :dl_src => local_hw, :nw_src => local_ip}.merge(match_type)
          outgoing_match[:nw_dst] = src_ip unless src_ip =~ /\/0$/
          queue_flow Flow.new(TABLE_LOAD_SRC, 3, outgoing_match, {:output_reg0 => nil})
        end

        def install_local_icmp hw, ip
          match_type = "dl_type=0x0800,nw_proto=1"

          learn_outgoing_match = "priority=#{2},idle_timeout=#{60},table=#{TABLE_LOAD_DST},#{match_type},NXM_OF_IN_PORT[],NXM_OF_ETH_SRC[],NXM_OF_ETH_DST[],NXM_OF_IP_SRC[],NXM_OF_IP_DST[]"
          learn_outgoing_actions = "output:NXM_NX_REG0[]"

          learn_incoming_match = "priority=#{2},idle_timeout=#{60},table=#{TABLE_LOAD_DST},#{match_type},NXM_OF_IN_PORT[]=NXM_NX_REG0[0..15],NXM_OF_ETH_SRC[]=NXM_OF_ETH_DST[],NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[],NXM_OF_IP_SRC[]=NXM_OF_IP_DST[],NXM_OF_IP_DST[]=NXM_OF_IP_SRC[]"
          learn_incoming_actions = "output:NXM_OF_IN_PORT[]"

          match = {:dl_type => 0x0800, :nw_proto => 1, :in_port => port_info.number, :dl_src => hw, :nw_src => ip}
          actions = [{:learn => "#{learn_outgoing_match},#{learn_outgoing_actions}"}, {:learn => "#{learn_incoming_match},#{learn_incoming_actions}"}, {:output_reg0 => nil}]

          queue_flow Flow.new(TABLE_LOAD_SRC, 1, match, actions)
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

          match = {:dl_type => 0x0800, :nw_proto => nw_proto, :in_port => port_info.number, :dl_src => hw, :nw_src => ip}
          actions = [{:learn => "#{learn_outgoing_match},#{learn_outgoing_actions}"}, {:learn => "#{learn_incoming_match},#{learn_incoming_actions}"}, {:output_reg0 => nil}]

          queue_flow Flow.new(TABLE_LOAD_SRC, 1, match, actions)
        end

        def active_flows
          @active_flows ||= Array.new
        end

        def queued_flows
          @queued_flows ||= Array.new
        end

        def queue_flow flow
          active_flows << flow
          queued_flows << flow
        end

      end

    end
  end
end
