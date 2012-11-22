# -*- coding: utf-8 -*-

require 'net/dhcp'
require 'racket'

module Dcmgr::VNet::OpenFlow

  class ServiceDhcp < ServiceBase
    include Dcmgr::Logger

    def install
      network.packet_handlers <<
        PacketHandler.new(Proc.new { |switch,port,message|
                            message.ipv4? and message.udp? and
                            (message.macda.to_s == 'ff:ff:ff:ff:ff:ff' || message.macda.to_s == self.mac) and
                            (message.ipv4_daddr.to_s == '255.255.255.255' || message.ipv4_daddr == self.ip) and
                            message.udp_src_port == 68 and message.udp_dst_port == 67 and
                            (port.port_type == PORT_TYPE_INSTANCE_NET or port.port_type == PORT_TYPE_INSTANCE_VNET)
                          }, Proc.new { |switch,port,message|
                            self.handle(switch, port, message)
                          })
      remove_flows

      if network.virtual
        # Catch DHCP requests.
        queue_flow Flow.new(TABLE_VIRTUAL_DST, 3, {:reg1 => network.id, :udp => nil, :dl_dst => self.mac, :nw_dst => self.ip.to_s, :tp_src => 68, :tp_dst => 67}, {:controller => nil})
        queue_flow Flow.new(TABLE_VIRTUAL_DST, 3, {:reg1 => network.id, :udp => nil, :dl_dst => 'ff:ff:ff:ff:ff:ff', :nw_dst => '255.255.255.255', :tp_src => 68, :tp_dst => 67}, {:controller => nil})

        flush_flows
      end
    end

    def handle(switch, port, message)
      if !message.udp?
        logger.debug "DHCP: Message is not UDP."
        return
      end

      dhcp_in = DHCP::Message.from_udp_payload(message.udp_payload)
      nw_services = network.services

      logger.debug "DHCP: message:#{dhcp_in.to_s}."

      # Check incoming type...
      message_type = dhcp_in.options.select { |each| each.type == $DHCP_MESSAGETYPE }
      return if message_type.empty? or message_type[0].payload.empty?

      # Verify dhcp_in values...

      if message_type[0].payload[0] == $DHCP_MSG_DISCOVER
        logger.debug "DHCP send: DHCP_MSG_OFFER."
        dhcp_out = DHCP::Offer.new(:options => [DHCP::MessageTypeOption.new(:payload => [$DHCP_MSG_OFFER])])
      elsif message_type[0].payload[0] == $DHCP_MSG_REQUEST
        logger.debug "DHCP send: DHCP_MSG_ACK."
        dhcp_out = DHCP::ACK.new(:options => [DHCP::MessageTypeOption.new(:payload => [$DHCP_MSG_ACK])])
      else
        logger.debug "DHCP send: no handler."
        return
      end

      dhcp_out.xid = dhcp_in.xid
      dhcp_out.yiaddr = Trema::IP.new(port.ip).to_i
      # Verify instead that discover has the right mac address.
      dhcp_out.chaddr = Trema::Mac.new(port.mac).to_a
      dhcp_out.siaddr = self.ip.to_i

      subnet_mask = IPAddr.new(IPAddr::IN4MASK, Socket::AF_INET).mask(network.prefix)

      dhcp_out.options << DHCP::ServerIdentifierOption.new(:payload => self.ip.to_short)
      dhcp_out.options << DHCP::IPAddressLeaseTimeOption.new(:payload => [ 0xff, 0xff, 0xff, 0xff ])
      dhcp_out.options << DHCP::BroadcastAddressOption.new(:payload => (network.ipv4_network | ~subnet_mask).to_short)

      if nw_services[:gateway]
        dhcp_out.options << DHCP::RouterOption.new(:payload => nw_services[:gateway].ip.to_short)
      end

      dhcp_out.options << DHCP::SubnetMaskOption.new(:payload => subnet_mask.to_short)

      if nw_services[:dns]
        dhcp_out.options << DHCP::DomainNameOption.new(:payload => nw_services[:dns].domain_name.unpack('C*')) if nw_services[:dns].domain_name
        dhcp_out.options << DHCP::DomainNameServerOption.new(:payload => nw_services[:dns].ip.to_short) if nw_services[:dns].ip
      end

      logger.debug "DHCP send: output:#{dhcp_out.to_s}."
      switch.datapath.send_udp(message.in_port,
                               self.mac.to_s, self.ip.to_s, 67,
                               port.mac.to_s, port.ip, 68,
                               dhcp_out.pack)
    end

  end

end
