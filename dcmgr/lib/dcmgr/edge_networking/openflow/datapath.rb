# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module OpenFlow

      # OpenFlow datapath allows us to send OF messages and ovs-ofctl
      # commands to a specific bridge/switch.
      class OpenFlowDatapath
        attr_reader :controller
        attr_reader :datapath_id
        attr_reader :ovs_ofctl

        def initialize ofc, dp_id, ofctl
          @controller = ofc
          @datapath_id = dp_id
          @ovs_ofctl = ofctl
        end

        def switch
          controller.switches[datapath_id]
        end

        def add_flow flow
          ovs_ofctl.add_flow flow
        end

        def add_flows flows
          ovs_ofctl.add_flows_from_list flows unless flows.empty?
        end

        def del_flows flows
          ovs_ofctl.del_flows_from_list flows unless flows.empty?
        end

        def send_message message
          controller.send_message datapath_id, message
        end

        def send_packet_out params
          controller.send_packet_out datapath_id, params
        end

        def send_arp out_port, op_code, src_hw, src_ip, dst_hw, dst_ip
          controller.send_arp datapath_id, out_port, op_code, src_hw, src_ip, dst_hw, dst_ip
        end

        def send_icmp out_port, options
          controller.send_icmp datapath_id, out_port, options
        end

        def send_udp out_port, src_hw, src_ip, src_port, dst_hw, dst_ip, dst_port, payload
          controller.send_udp datapath_id, out_port, src_hw, src_ip, src_port, dst_hw, dst_ip, dst_port, payload
        end
      end

    end
  end
end
