# -*- coding: utf-8 -*-

require 'eventmachine'
require 'racket'

class IPAddr
  def to_short
    [(@addr >> 24) & 0xff, (@addr >> 16) & 0xff, (@addr >> 8) & 0xff, @addr & 0xff]
  end
end

module Dcmgr
  module VNet
    module OpenFlow

      class OpenFlowController < Trema::Controller
        include Dcmgr::Logger
        include OpenFlowConstants

        attr_reader :default_ofctl
        attr_reader :switches

        def initialize service_openflow
          @service_openflow = service_openflow
          @default_ofctl = OvsOfctl.new

          @switches = {}
        end

        def start
          logger.info "starting OpenFlow controller."
        end

        def switch_ready datapath_id
          logger.info "switch_ready from %#x." % datapath_id

          # We currently rely on the ovs database to figure out the
          # bridge name, as it is randomly generated each time the
          # bridge is created unless explicitly set by the user.
          bridge_name = @default_ofctl.get_bridge_name(datapath_id)
          raise "No bridge found matching: datapath_id:%016x" % datapath_id if bridge_name.nil?

          # Sometimes ovs changes the datapath ID and reconnects.
          switches.delete_if { |dpid,switch| switch.switch_name == bridge_name }

          ofctl = @default_ofctl.dup
          ofctl.switch_name = bridge_name

          # There is no need to clean up the old switch, as all the
          # previous flows are removed. Just let it rebuild everything.
          #
          # This might not be optimal in cases where the switch got
          # disconnected for a short period, as Open vSwitch has the
          # ability to keep flows between sessions.
          switches[datapath_id] = OpenFlowSwitch.new(OpenFlowDatapath.new(self, datapath_id, ofctl), bridge_name)
          switches[datapath_id].update_bridge_ipv4
          switches[datapath_id].switch_ready
        end

        def features_reply datapath_id, message
          raise "No switch found." unless switches.has_key? datapath_id
          switches[datapath_id].features_reply message
        end

        def insert_port switch, port
          if port.port_info.number >= OFPP_MAX
            # Do nothing...
          elsif port.port_info.name =~ /^eth/
            @service_openflow.add_eth switch, port
          elsif port.port_info.name =~ /^vif-/
            @service_openflow.add_instance switch, port
          elsif port.port_info.name =~ /^t-/
            @service_openflow.add_tunnel switch, port
          else
          end
        end

        def delete_port switch, port
          port.lock.synchronize {
            return unless port.is_active
            port.is_active = false

            port.networks.each { |network|
              network.remove_port port.port_info.number
              network.update
            }

            port.datapath.del_flows port.active_flows
            port.active_flows.clear
            port.queued_flows.clear
            switch.ports.delete port.port_info.number
          }
        end

        def port_status datapath_id, message
          raise "No switch found." unless switches.has_key? datapath_id
          switches[datapath_id].port_status message
        end

        def packet_in datapath_id, message
          raise "No switch found." unless switches.has_key? datapath_id
          switches[datapath_id].packet_in message
        end

        def vendor datapath_id, message
          logger.debug "vendor message from #{datapath_id.to_hex}."
          logger.debug "transaction_id: #{message.transaction_id.to_hex}"
          logger.debug "data: #{message.buffer.unpack('H*')}"
        end

        #
        # Public functions
        #

        def send_udp datapath_id, out_port, src_hw, src_ip, src_port, dst_hw, dst_ip, dst_port, payload
          raw_out = Racket::Racket.new
          raw_out.l2 = Racket::L2::Ethernet.new
          raw_out.l2.src_mac = src_hw
          raw_out.l2.dst_mac = dst_hw

          raw_out.l3 = Racket::L3::IPv4.new
          raw_out.l3.src_ip = src_ip
          raw_out.l3.dst_ip = dst_ip
          raw_out.l3.protocol = 0x11
          raw_out.l3.ttl = 128

          raw_out.l4 = Racket::L4::UDP.new
          raw_out.l4.src_port = src_port
          raw_out.l4.dst_port = dst_port
          raw_out.l4.payload = payload

          raw_out.l4.fix!(raw_out.l3.src_ip, raw_out.l3.dst_ip)

          raw_out.layers.compact.each { |l|
            logger.debug "send udp: layer:#{l.pretty}."
          }

          send_packet_out(datapath_id,
                          :data => raw_out.pack.ljust(64, "\0"),
                          :actions => Trema::ActionOutput.new( :port => out_port ) )
        end

        def send_arp datapath_id, out_port, op_code, src_hw, src_ip, dst_hw, dst_ip
          raw_out = Racket::Racket.new
          raw_out.l2 = Racket::L2::Ethernet.new
          raw_out.l2.ethertype = Racket::L2::Ethernet::ETHERTYPE_ARP
          raw_out.l2.src_mac = src_hw.nil? ? '00:00:00:00:00:00' : src_hw
          raw_out.l2.dst_mac = dst_hw.nil? ? 'FF:FF:FF:FF:FF:FF' : dst_hw

          raw_out.l3 = Racket::L3::ARP.new
          raw_out.l3.opcode = op_code
          raw_out.l3.sha = src_hw.nil? ? '00:00:00:00:00:00' : src_hw
          raw_out.l3.spa = src_ip.nil? ? '0.0.0.0' : src_ip
          raw_out.l3.tha = dst_hw.nil? ? '00:00:00:00:00:00' : dst_hw
          raw_out.l3.tpa = dst_ip.nil? ? '0.0.0.0' : dst_ip

          raw_out.layers.compact.each { |l|
            logger.debug "ARP packet: layer:#{l.pretty}."
          }

          send_packet_out(datapath_id,
                          :data => raw_out.pack.ljust(64, "\0"),
                          :actions => Trema::ActionOutput.new( :port => out_port ) )
        end

        def send_icmp datapath_id, out_port, options
          raw_out = Racket::Racket.new
          raw_out.l2 = Racket::L2::Ethernet.new
          raw_out.l2.src_mac = options[:src_hw]
          raw_out.l2.dst_mac = options[:dst_hw]

          raw_out.l3 = Racket::L3::IPv4.new
          raw_out.l3.src_ip = options[:src_ip]
          raw_out.l3.dst_ip = options[:dst_ip]
          raw_out.l3.protocol = 0x1
          raw_out.l3.ttl = 128

          case options[:op_code]
          when Racket::L4::ICMPGeneric::ICMP_TYPE_ECHO_REQUEST
            raw_out.l4 = Racket::L4::ICMPEchoReply.new
            raw_out.l4.id = options[:id]
            raw_out.l4.sequence = options[:sequence]
          else
            raise "Unsupported ICMP type."
          end

          # raw_out.l4.payload = payload
          raw_out.l4.fix!

          raw_out.layers.compact.each { |l|
            logger.debug "ICMP packet: layer:#{l.pretty}."
          }

          send_packet_out(datapath_id,
                          :data => raw_out.pack.ljust(64, "\0"),
                          :actions => Trema::ActionOutput.new(:port => out_port))
        end

      end


      class OpenFlowForwardingEntry
        attr_reader :mac
        attr_reader :port_no

        def initialize mac, port_no
          @mac = mac
          @port_no = port_no
        end

        def update port_no
          @port_no = port_no
        end
      end

      class OpenFlowForwardingDatabase
        def initialize
          @db = {}
        end

        def port_no_of mac
          dest = @db[mac]

          if dest
            dest.port_no
          else
            nil
          end
        end

        def learn mac, port_no
          entry = @db[mac]

          if entry
            entry.update port_no
          else
            @db[new_entry.mac] = ForwardingEntry.new(mac, port_no)
          end
        end
      end

    end
  end
end
