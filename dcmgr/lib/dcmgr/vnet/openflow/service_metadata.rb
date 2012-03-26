# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceMetadata
    include Dcmgr::Logger
    include OpenFlowConstants

    attr_reader :datapath

    attr_reader :ip
    attr_reader :mac
    attr_reader :port
    attr_reader :output
    
    def initialize(dp, ip, port)
      @datapath = dp
      @ip = ip
      @port = port
    end
  
    def install output_port, dest_hw
      logger.info "Adding metadata server: port:#{output_port} mac:#{dest_hw.to_s} ip:#{ip.to_s}/#{port}."

      @output = output_port
      @mac = dest_hw

      @arp_retry.cancel if @arp_retry
      @arp_retry = nil

      # Currently only add for the physical networks.
      flows = []
      flows << Flow.new(TABLE_CLASSIFIER, 5, {:tcp => nil, :nw_dst => '169.254.169.254', :tp_dst => 80}, {:resubmit => TABLE_METADATA_OUTGOING})
      flows << Flow.new(TABLE_CLASSIFIER, 5, {:tcp => nil, :nw_src => ip.to_s, :tp_src => port}, {:resubmit => TABLE_METADATA_INCOMING})

      # Replace with dnat entries instead of custom tables.
      flows << Flow.new(TABLE_METADATA_OUTGOING, 1, {}, {:controller => nil})

      datapath.add_flows flows        
    end

    def request_mac switch, port_number, local_hw
      logger.info "Requesting metadata server mac: port:#{port_number} mac:#{local_hw.to_s} ip:#{ip.to_s}/#{port}."

      switch.packet_handlers <<
        PacketHandler.new(Proc.new { |switch,port,message|
                            port.port_info.number == port_number and
                            port.network.services[:metadata_server].output.nil? and
                            message.arp? and
                            message.arp_oper == Racket::L3::ARP::ARPOP_REPLY and
                            message.arp_spa.to_s == port.network.services[:metadata_server].ip.to_s and
                            message.arp_tpa.to_s == Isono::Util.default_gw_ipaddr.to_s
                          }, Proc.new { |switch,port,message|
                            self.install(message.in_port, message.arp_sha)
                          })

      flows = [Flow.new(TABLE_ARP_ROUTE, 3, {
                          :in_port => port_number, :arp => nil,
                          :dl_dst => local_hw.to_s, :nw_dst => Isono::Util.default_gw_ipaddr,
                          :nw_src => ip.to_s},
                        {:controller => nil, :local => nil})]

      datapath.add_flows flows        
      datapath.send_arp(port_number, Racket::L3::ARP::ARPOP_REQUEST,
                        local_hw.to_s, Isono::Util.default_gw_ipaddr.to_s, nil, ip.to_s)

      @arp_retry = EM::PeriodicTimer.new(10) {
        datapath.send_arp(port_number, Racket::L3::ARP::ARPOP_REQUEST,
                          local_hw.to_s, Isono::Util.default_gw_ipaddr.to_s, nil, ip.to_s)
      }
    end

  end

end
