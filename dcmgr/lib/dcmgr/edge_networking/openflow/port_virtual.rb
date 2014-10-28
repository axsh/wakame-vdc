# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  module PortVirtual
    include OpenFlowConstants

    def init_instance_vnet(network, hw, ip)
      @port_type = PORT_TYPE_INSTANCE_VNET
      queue_flow Flow.new(TABLE_CLASSIFIER,  8, {:in_port => port_info.number}, {:load_reg1 => network.id, :resubmit => TABLE_VIRTUAL_SRC})
      # TABLE_VIRTUAL_SRC-4 reg1=network.id,reg2=0x0 actions=drop
      queue_flow Flow.new(TABLE_VIRTUAL_SRC, 7, {:in_port => port_info.number, :ip => nil, :dl_src => hw, :nw_src => ip}, {:resubmit => TABLE_VIRTUAL_DST})
      queue_flow Flow.new(TABLE_VIRTUAL_SRC, 7, {:in_port => port_info.number, :ip => nil, :dl_src => hw, :nw_src => '0.0.0.0'}, {:resubmit => TABLE_VIRTUAL_DST})
      queue_flow Flow.new(TABLE_VIRTUAL_SRC, 9, {:in_port => port_info.number, :arp => nil, :dl_src => hw, :nw_src => ip, :arp_sha => hw}, {:resubmit => TABLE_VIRTUAL_DST})
      queue_flow Flow.new(TABLE_VIRTUAL_DST, 2, {:reg1 => network.id, :dl_dst => hw}, {:output => port_info.number})
    end

  end

end
