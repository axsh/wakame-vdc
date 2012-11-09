# -*- coding: utf-8 -*-

require 'racket'

module Dcmgr::VNet::OpenFlow

  class IcmpHandler
    include Dcmgr::Logger
    include OpenFlowConstants

    attr_reader :network
    attr_reader :entries

    def initialize
      @entries = {}
    end

    def install(nw)
      @network = nw
      network.packet_handlers <<
        PacketHandler.new(Proc.new { |switch,port,message|
                            message.icmpv4? && message.icmpv4_type == Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST
                          }, Proc.new { |switch,port,message|
                            self.handle(port, message)
                          })
    end

    def add(mac, ip, owner)
      if entries.has_key? ip.to_s
        logger.debug "Duplicate ip in icmp handler: ip:#{ip.to_s}."
        return
      end

      if network.virtual
        # TODO: Add ICMP type...
        flow = Flow.new(TABLE_VIRTUAL_DST, 3, {:reg1 => network.id, :icmp => nil, :nw_dst => ip.to_s}, {:controller => nil})
      else
        raise "Only virtual networks handled atm."
      end

      network.datapath.add_flows([flow])
      entries[ip.to_s] = { :mac => mac, :owner => owner }
    end

    def handle(port, message)
      entry = entries[message.ipv4_daddr.to_s]

      logger.debug "icmp_handler: tpa:'#{message.ipv4_daddr.to_s}' entry:#{entry[:mac].inspect}."
      return if entry.nil?

      payload = message.ipv4_payload
      payload = payload.byteslice(8, payload.bytesize - 8) if payload

      network.datapath.send_icmp(message.in_port, {
                                   :op_code => Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REPLY,
                                   :src_hw => entry[:mac], :src_ip => message.ipv4_daddr.to_s,
                                   :dst_hw => message.macsa.to_s, :dst_ip => message.ipv4_saddr.to_s,
                                   :id => message.icmpv4_id,
                                   :sequence => message.icmpv4_seq,
                                   :payload => payload,
                                 })
    end

  end

end
