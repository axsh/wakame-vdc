# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  module PortPhysical
    include OpenFlowConstants

    def init_instance_net(network, hw, ip)
      @port_type = PORT_TYPE_INSTANCE_NET
      queue_flow Flow.new(TABLE_MAC_ROUTE,      1, {:dl_dst => hw}, {:output => port_info.number})
      queue_flow Flow.new(TABLE_CLASSIFIER,     2, {:in_port => port_info.number, :dl_src => hw}, {:resubmit => TABLE_ROUTE_DIRECTLY})
      queue_flow Flow.new(TABLE_ROUTE_DIRECTLY, 1, {:dl_dst => hw}, {:output => port_info.number})
      queue_flow Flow.new(TABLE_LOAD_DST,       1, {:dl_dst => hw}, {:drop => nil})
    end

    #
    # Install flows:
    #

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

  end

end
