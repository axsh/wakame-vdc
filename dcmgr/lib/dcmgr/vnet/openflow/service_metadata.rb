# -*- coding: utf-8 -*-

module Dcmgr::VNet::OpenFlow

  class ServiceMetadata < ServiceBase
    include Dcmgr::Logger

    def install
      logger.info "Adding metadata server: port:#{@of_port} mac:#{@mac.to_s} ip:#{ip.to_s}/#{listen_port}."

      remove_flows

      # Currently only add for the physical networks.
      queue_flow Flow.new(TABLE_CLASSIFIER, 5, {:tcp => nil, :nw_dst => '169.254.169.254', :tp_dst => 80}, {:resubmit => TABLE_METADATA_OUTGOING})
      queue_flow Flow.new(TABLE_CLASSIFIER, 5, {:tcp => nil, :nw_src => ip.to_s, :tp_src => listen_port}, {:resubmit => TABLE_METADATA_INCOMING})

      # Replace with dnat entries instead of custom tables.
      queue_flow Flow.new(TABLE_METADATA_OUTGOING, 1, {}, {:controller => nil})

      flush_flows

      if self.ip.to_s == switch.bridge_ipv4
        install_flows
      end
    end

    def request_mac(switch, port)
      port_number = port.port_info.number
      local_hw = port.port_info.hw_addr

      logger.info "Requesting metadata server mac: port:#{port_number} mac:#{local_hw.to_s} ip:#{self.ip.to_s}/#{listen_port}."

      # This needs to be per-network handler.
      network.packet_handlers <<
        PacketHandler.new(Proc.new { |switch,port,message|
                            port.port_info.number == port_number and
                            network.services[:metadata].of_port.nil? and
                            message.arp? and
                            message.arp_oper == Racket::L3::ARP::ARPOP_REPLY and
                            message.arp_spa.to_s == network.services[:metadata].ip.to_s and
                            message.arp_tpa.to_s == switch.bridge_ipv4
                          }, Proc.new { |switch,port,message|
                            self.of_port = port_number
                            self.mac = message.arp_sha
                            self.install_flows
                          })

      queue_flow Flow.new(TABLE_ARP_ROUTE, 3, {
                            :in_port => port_number, :arp => nil,
                            :dl_dst => local_hw.to_s, :nw_dst => switch.bridge_ipv4,
                            :nw_src => ip.to_s},
                          {:controller => nil, :local => nil})
      flush_flows

      switch.datapath.send_arp(port_number, Racket::L3::ARP::ARPOP_REQUEST,
                               local_hw.to_s, switch.bridge_ipv4.to_s, nil, ip.to_s)

      @arp_retry = EM::PeriodicTimer.new(10) {
        switch.datapath.send_arp(port_number, Racket::L3::ARP::ARPOP_REQUEST,
                                 local_hw.to_s, switch.bridge_ipv4.to_s, nil, ip.to_s)
      }
    end

    def install_flows
      logger.info "Installing metadata server flows: port:#{@of_port} mac:#{@mac.to_s} ip:#{ip.to_s}/#{listen_port}."

      @arp_retry.cancel if @arp_retry
      @arp_retry = nil

      network.packet_handlers <<
        PacketHandler.new(Proc.new { |switch,port,message|
                            network.services[:metadata] and
                            network.services[:metadata].of_port and
                            message.ipv4? and message.tcp? and
                            message.ipv4_daddr.to_s == "169.254.169.254" and message.tcp_dst_port == 80
                          }, Proc.new { |switch,port,message|
                            metadata_server = network.services[:metadata]

                            if metadata_server.ip.to_s == switch.bridge_ipv4.to_s
                              switch.install_dnat_entry(message, TABLE_METADATA_OUTGOING, TABLE_METADATA_INCOMING,
                                                        metadata_server.of_port,
                                                        network.local_hw,
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
                                                            :actions => Trema::ActionOutput.new(:port => OpenFlowController::OFPP_TABLE))
                          })
    end

  end

end
