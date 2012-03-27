# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceMetadata < ServiceBase
    include Dcmgr::Logger

    def install port, remote_mac
      logger.info "Adding metadata server: port:#{port} mac:#{remote_mac.to_s} ip:#{ip.to_s}/#{listen_port}."

      @of_port = port
      @mac = remote_mac

      @arp_retry.cancel if @arp_retry
      @arp_retry = nil

      # Currently only add for the physical networks.
      flows = []
      flows << Flow.new(TABLE_CLASSIFIER, 5, {:tcp => nil, :nw_dst => '169.254.169.254', :tp_dst => 80}, {:resubmit => TABLE_METADATA_OUTGOING})
      flows << Flow.new(TABLE_CLASSIFIER, 5, {:tcp => nil, :nw_src => ip.to_s, :tp_src => listen_port}, {:resubmit => TABLE_METADATA_INCOMING})

      # Replace with dnat entries instead of custom tables.
      flows << Flow.new(TABLE_METADATA_OUTGOING, 1, {}, {:controller => nil})

      switch.datapath.add_flows flows
      switch.packet_handlers <<
        PacketHandler.new(Proc.new { |switch,port,message|
                            port.network.services[:metadata_server] and
                            port.network.services[:metadata_server].of_port and
                            message.ipv4? and message.tcp? and
                            message.ipv4_daddr.to_s == "169.254.169.254" and message.tcp_dst_port == 80
                          }, Proc.new { |switch,port,message|
                            metadata_server = port.network.services[:metadata_server]

                            if metadata_server.ip.to_s == Isono::Util.default_gw_ipaddr.to_s
                              switch.install_dnat_entry(message, TABLE_METADATA_OUTGOING, TABLE_METADATA_INCOMING,
                                                        metadata_server.of_port,
                                                        port.network.local_hw,
                                                        metadata_server.ip.to_s,
                                                        metadata_server.listen_port)
                            else
                              switch.install_dnat_entry(message, TABLE_METADATA_OUTGOING, TABLE_METADATA_INCOMING,
                                                        metadata_server.of_port,
                                                        metadata_server.mac,
                                                        metadata_server.ip.to_s,
                                                        metadata_server.listen_port)
                            end

                            switch.datapath.send_packet_out(:packet_in => message,
                                                            :actions => Trema::ActionOutput.new(:port => Dcmgr::VNet::OpenFlow::OpenFlowController::OFPP_TABLE))
                          })
    end

    def request_mac switch, port
      port_number = port.port_info.number
      local_hw = port.port_info.hw_addr

      logger.info "Requesting metadata server mac: port:#{port_number} mac:#{local_hw.to_s} ip:#{ip.to_s}/#{listen_port}."

      # This needs to be per-network handler.
      switch.packet_handlers <<
        PacketHandler.new(Proc.new { |switch,port,message|
                            port.port_info.number == port_number and
                            port.network.services[:metadata_server].of_port.nil? and
                            message.arp? and
                            message.arp_oper == Racket::L3::ARP::ARPOP_REPLY and
                            message.arp_spa.to_s == port.network.services[:metadata_server].ip.to_s and
                            message.arp_tpa.to_s == Isono::Util.default_gw_ipaddr.to_s
                          }, Proc.new { |switch,port,message|
                            self.install(port_number, message.arp_sha)
                          })

      flows = [Flow.new(TABLE_ARP_ROUTE, 3, {
                          :in_port => port_number, :arp => nil,
                          :dl_dst => local_hw.to_s, :nw_dst => Isono::Util.default_gw_ipaddr,
                          :nw_src => ip.to_s},
                        {:controller => nil, :local => nil})]

      switch.datapath.add_flows flows        
      switch.datapath.send_arp(port_number, Racket::L3::ARP::ARPOP_REQUEST,
                               local_hw.to_s, Isono::Util.default_gw_ipaddr.to_s, nil, ip.to_s)

      @arp_retry = EM::PeriodicTimer.new(10) {
        switch.datapath.send_arp(port_number, Racket::L3::ARP::ARPOP_REQUEST,
                                 local_hw.to_s, Isono::Util.default_gw_ipaddr.to_s, nil, ip.to_s)
      }
    end

  end

end
