# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceDhcp < ServiceBase
    include Dcmgr::Logger

    def install(network)
      network.packet_handlers <<
        PacketHandler.new(Proc.new { |switch,port,message|
                            message.ipv4? and message.udp? and
                            message.udp_src_port == 68 and message.udp_dst_port == 67 and
                            (port.port_type == PORT_TYPE_INSTANCE_NET or port.port_type == PORT_TYPE_INSTANCE_VNET)
                          }, Proc.new { |switch,port,message|
                            switch.handle_dhcp(port, message)
                          })
    end

  end
  
end
