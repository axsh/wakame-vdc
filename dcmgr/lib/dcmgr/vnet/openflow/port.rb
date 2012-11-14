# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class OpenFlowPort
    include OpenFlowConstants
    include FlowGroup

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

    def init_instance_subnet(network, eth_port, hw, ip)
      queue_flow Flow.new(TABLE_CLASSIFIER, 8, {:in_port => eth_port, :dl_dst => hw}, {:load_reg1 => network.id, :load_reg2 => eth_port, :resubmit => TABLE_VIRTUAL_SRC})
    end

  end

end
