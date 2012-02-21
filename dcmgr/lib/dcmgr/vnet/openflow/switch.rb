# -*- coding: utf-8 -*-

require 'net/dhcp'
require 'racket'

module Dcmgr
  module VNet
    module OpenFlow

      class OpenFlowSwitch
        include Dcmgr::Logger
        include OpenFlowConstants
        
        attr_reader :datapath
        attr_reader :ports
        attr_reader :networks
        attr_reader :switch_name
        attr_reader :local_hw
        
        def initialize dp, name
          @datapath = dp
          @ports = {}
          @networks = {}
          @switch_name = name
        end
        
        def switch_ready
          logger.info "switch_ready: name:#{switch_name} datapath_id:%#x." % datapath.datapath_id

          # There's a short period of time between the switch being
          # activated and features_reply installing flow.
          datapath.send_message Trema::FeaturesRequest.new
        end

        def features_reply message
          logger.info  "features_reply from %#x." % message.datapath_id
          logger.debug "datapath_id: %#x" % message.datapath_id
          logger.debug "transaction_id: %#x" % message.transaction_id
          logger.debug "n_buffers: %u" % message.n_buffers
          logger.debug "n_tables: %u" % message.n_tables
          logger.debug "capabilities: %u" % message.capabilities
          logger.debug "actions: %u" % message.actions
          logger.info  "ports: %s" % message.ports.collect { | each | each.number }.sort.join( ", " )

          message.ports.each do | each |
            if each.number == OpenFlowController::OFPP_LOCAL
              @local_hw = each.hw_addr
              logger.debug "OFPP_LOCAL: hw_addr:#{local_hw.to_s}"
            end
          end

          message.ports.each do | each |
            port = OpenFlowPort.new(datapath, each)
            port.is_active = true
            ports[each.number] = port

            datapath.controller.insert_port self, port
          end

          # Build the routing flow table and some other flows using
          # ovs-ofctl due to the lack of multiple tables support, which
          # was introduced in of-spec 1.1.

          #
          # Classification
          #
          flows = []

          # DHCP queries from instances and network should always go to
          # local host, while queries from local host should go to the
          # network.
          flows << Flow.new(TABLE_CLASSIFIER, 3, {:arp => nil}, {:resubmit => TABLE_ARP_ANTISPOOF})
          flows << Flow.new(TABLE_CLASSIFIER, 3, {:icmp => nil}, {:resubmit => TABLE_LOAD_DST})
          flows << Flow.new(TABLE_CLASSIFIER, 3, {:tcp => nil}, {:resubmit => TABLE_LOAD_DST})
          flows << Flow.new(TABLE_CLASSIFIER, 3, {:udp => nil}, {:resubmit => TABLE_LOAD_DST})

          flows << Flow.new(TABLE_CLASSIFIER, 2, {:in_port => OpenFlowController::OFPP_LOCAL}, {:resubmit => TABLE_ROUTE_DIRECTLY})

          #
          # MAC address routing
          #

          flows << Flow.new(TABLE_MAC_ROUTE, 1, {:dl_dst => local_hw.to_s}, {:local => nil})
          flows << Flow.new(TABLE_ROUTE_DIRECTLY, 1, {:dl_dst => local_hw.to_s}, {:local => nil})
          flows << Flow.new(TABLE_LOAD_DST, 1, {:dl_dst => local_hw.to_s}, [{:load_reg0 => OpenFlowController::OFPP_LOCAL}, {:resubmit => TABLE_LOAD_SRC}])

          # Some flows depend on only local being able to send packets
          # with the local mac and ip address, so drop those.
          flows << Flow.new(TABLE_LOAD_SRC, 6, {:in_port => OpenFlowController::OFPP_LOCAL}, {:output_reg0 => nil})
          flows << Flow.new(TABLE_LOAD_SRC, 5, {:dl_src => local_hw.to_s}, {:drop => nil})
          flows << Flow.new(TABLE_LOAD_SRC, 5, {:ip => nil, :nw_src => Isono::Util.default_gw_ipaddr}, {:drop =>nil})

          #
          # ARP routing table
          #

          # ARP anti-spoofing flows.
          flows << Flow.new(TABLE_ARP_ANTISPOOF, 1, {:arp => nil, :in_port => OpenFlowController::OFPP_LOCAL}, {:resubmit => TABLE_ARP_ROUTE})

          # Replace drop actions with table default action.
          flows << Flow.new(TABLE_ARP_ANTISPOOF, 0, {:arp => nil}, {:drop => nil})

          # TODO: How will this handle packets from host or eth0 that
          # spoof the mac of an instance?
          flows << Flow.new(TABLE_ARP_ROUTE, 1, {:arp => nil, :dl_dst => local_hw.to_s}, {:local => nil})

          datapath.add_flows flows        
        end

        def port_status message
          logger.info "port_status from %#x." % message.datapath_id
          logger.debug "datapath_id: %#x" % message.datapath_id
          logger.debug "reason: #{message.reason}"
          logger.debug "in_port: #{message.phy_port.number}"
          logger.debug "hw_addr: #{message.phy_port.hw_addr}"
          logger.debug "state: %#x" % message.phy_port.state

          case message.reason
          when OpenFlowController::OFPPR_ADD
            logger.info "Adding port: port:#{message.phy_port.number} name:#{message.phy_port.name}."
            raise "OpenFlowPort" if ports.has_key? message.phy_port.number

            datapath.controller.delete_port ports[message.phy_port.number] if ports.has_key? message.phy_port.number

            port = OpenFlowPort.new(datapath, message.phy_port)
            port.is_active = true
            ports[message.phy_port.number] = port

            datapath.controller.insert_port self, port

          when OpenFlowController::OFPPR_DELETE
            logger.info "Deleting instance port: port:#{message.phy_port.number}."
            raise "UnknownOpenflowPort" if not ports.has_key? message.phy_port.number

            datapath.controller.delete_port ports[message.phy_port.number] if ports.has_key? message.phy_port.number

          when OpenFlowController::OFPPR_MODIFY
            logger.info "Ignoring port modify..."
          end
        end

        def packet_in message
          port = ports[message.in_port]

          if port.nil?
            logger.debug "Dropping processing of packet, unknown port."
            return
          end

          if message.arp?
            logger.debug "Got ARP packet; port:#{message.in_port} network:#{port.network.nil? ? 'nil' : port.network.id} oper:#{message.arp_oper} source:#{message.arp_sha.to_s}/#{message.arp_spa.to_s} dest:#{message.arp_tha.to_s}/#{message.arp_tpa.to_s}."

            return if port.network.nil?
            network = port.network

            # Add a generic ARP handler.
            if network.metadata_server_output.nil? and
                !network.metadata_server_ip.nil? and
                !network.metadata_server_port.nil? and
                message.arp_oper == Racket::L3::ARP::ARPOP_REPLY and
                message.arp_spa.to_s == network.metadata_server_ip.to_s and
                message.arp_tpa.to_s == Isono::Util.default_gw_ipaddr.to_s
              
              network.install_metadata_server message.in_port, message.arp_sha

            elsif message.arp_oper == Racket::L3::ARP::ARPOP_REQUEST and message.arp_tpa.to_i == port.network.dhcp_ip.to_i
              datapath.send_arp(message.in_port, Racket::L3::ARP::ARPOP_REPLY,
                                port.network.dhcp_hw.to_s, port.network.dhcp_ip.to_s,
                                message.macsa.to_s, message.arp_spa.to_s)
            end

            return
          end

          if message.ipv4? and message.tcp?
            logger.debug "Got IPv4/TCP packet; port:#{message.in_port} network:#{port.network.nil? ? 'nil' : port.network.id} source:#{message.ipv4_saddr.to_s}:#{message.tcp_src_port} dest:#{message.ipv4_daddr.to_s}:#{message.tcp_dst_port}."

            return if port.network.nil?
            network = port.network

            # Add dynamic NAT flows for meta-data connections.
            if !network.metadata_server_output.nil? and
                message.ipv4_daddr.to_s == "169.254.169.254" and message.tcp_dst_port == 80

              if network.metadata_server_ip.to_s == Isono::Util.default_gw_ipaddr.to_s
                install_dnat_entry(message, TABLE_METADATA_OUTGOING, TABLE_METADATA_INCOMING,
                                   network.metadata_server_output,
                                   network.local_hw,
                                   network.metadata_server_ip.to_s,
                                   network.metadata_server_port)
              else
                install_dnat_entry(message, TABLE_METADATA_OUTGOING, TABLE_METADATA_INCOMING,
                                   network.metadata_server_output,
                                   network.metadata_server_mac,
                                   network.metadata_server_ip.to_s,
                                   network.metadata_server_port)
              end

              datapath.send_packet_out(:packet_in => message, :actions => Trema::ActionOutput.new( :port => OpenFlowController::OFPP_TABLE ))
              return
            end

          end

          if message.ipv4? and message.udp?
            logger.debug "Got IPv4/UDP packet; port:#{message.in_port} source:#{message.ipv4_saddr.to_s}:#{message.udp_src_port} dest:#{message.ipv4_daddr.to_s}:#{message.udp_dst_port}."

            return if port.network.nil?

            if message.udp_src_port == 68 and message.udp_dst_port == 67
              dhcp_in = DHCP::Message.from_udp_payload(message.udp_payload)

              logger.debug "DHCP: message:#{dhcp_in.to_s}."

              if port.network.dhcp_ip.nil?
                logger.debug "DHCP: Port has no dhcp_ip: port:#{port.port_info.inspect}"
                return
              end

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
              dhcp_out.chaddr = Trema::Mac.new(port.mac).to_short
              dhcp_out.siaddr = port.network.dhcp_ip.to_i

              subnet_mask = IPAddr.new(IPAddr::IN4MASK, Socket::AF_INET).mask(port.network.prefix)

              dhcp_out.options << DHCP::ServerIdentifierOption.new(:payload => port.network.dhcp_ip.to_short)
              dhcp_out.options << DHCP::IPAddressLeaseTimeOption.new(:payload => [ 0xff, 0xff, 0xff, 0xff ])
              dhcp_out.options << DHCP::BroadcastAddressOption.new(:payload => (port.network.ipv4_network | ~subnet_mask).to_short)
              dhcp_out.options << DHCP::DomainNameOption.new(:payload => port.network.domain_name.unpack('C*'))
              dhcp_out.options << DHCP::DomainNameServerOption.new(:payload => port.network.dns_ip.to_short) unless port.network.dns_ip.nil?
              dhcp_out.options << DHCP::RouterOption.new(:payload => port.network.ipv4_gw.to_short) unless port.network.ipv4_gw.nil?
              dhcp_out.options << DHCP::SubnetMaskOption.new(:payload => subnet_mask.to_short)

              logger.debug "DHCP send: output:#{dhcp_out.to_s}."
              datapath.send_udp(message.in_port, port.network.dhcp_hw.to_s, port.network.dhcp_ip.to_s, 67, port.mac.to_s, port.ip, 68, dhcp_out.pack)
            end
          end
        end

        def install_dnat_entry message, outgoing_table, incoming_table, dest_port, dest_hw, dest_ip, dest_tp
          logger.info "Installing DNAT entry: #{dest_port} #{dest_hw} #{dest_ip}:#{dest_tp}"

          msg_nw_src = message.ipv4_saddr.to_s
          msg_nw_dst = message.ipv4_daddr.to_s

          # We don't need to match against the IP or port used by the
          # classifier to pass the flow to these tables.

          prefix = {:idle_timeout => 300, :tcp => nil}

          prefix_outgoing = {:in_port => message.in_port}.merge(prefix)
          match_outgoing = {:dl_src => message.macsa.to_s, :dl_dst => message.macda.to_s, :nw_src => msg_nw_src, :tp_src => message.tcp_src_port}
          action_outgoing = [{:mod_dl_dst => dest_hw, :mod_nw_dst => dest_ip, :mod_tp_dst => dest_tp}, {:output => dest_port}]

          prefix_incoming = {:in_port => dest_port}
          match_incoming = {:dl_src => dest_hw.to_s, :dl_dst => message.macsa.to_s, :nw_dst => msg_nw_src, :tp_dst => message.tcp_src_port}
          action_incoming = [{:mod_dl_src => message.macda.to_s, :mod_nw_src => msg_nw_dst, :mod_tp_src => message.tcp_dst_port}, {:output => message.in_port}]

          datapath.add_flows [Flow.new(outgoing_table, 3, match_outgoing, action_outgoing),
                              Flow.new(incoming_table, 3, match_incoming, action_incoming)]
        end

      end

    end
  end
end
