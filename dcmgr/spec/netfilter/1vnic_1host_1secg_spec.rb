# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"
require_relative 'helper_classes'
require_relative 'matchers/have_applied_vnic'
require_relative 'matchers/have_applied_secg'

describe "SGHandler and NetfilterAgent" do
  context "with 1 vnic, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }
    let(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let(:vnic) { create_vnic(host, [secg], "525400033c48", network, "10.0.0.1") }
    let(:vnic_id) { vnic.canonical_uuid }

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      handler.init_vnic(vnic_id)

      nfa(host).should have_applied_vnic(vnic).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnic])

      handler.destroy_vnic(vnic_id)
      vnic.destroy

      nfa(host).should_not have_applied_vnic(vnic)
      nfa(host).should_not have_applied_secg(secg)
      nfa(host).should have_nothing_applied
    end

    context "with gateway, dns, dhcp and metadata server set" do
      let(:network) { Fabricate(:network,
        ipv4_gw: "10.0.0.1",
        dns_server: "8.8.8.8",
        dhcp_server: "10.0.0.2",
        metadata_server: "10.0.0.3",
        metadata_server_port: 9876
      )}

      it "applies standard rules for gateway, dhcp and dns" do
        handler.init_vnic(vnic_id)
        nfa(host).should have_applied_vnic(vnic)
      end
    end

    context "with security group rules set" do
      let(:secg) {
        Fabricate(:secg, rule: "
        # demo rule for demo instances
        tcp:22,22,ip4:0.0.0.0
        tcp:80,80,ip4:0.0.0.0
        udp:53,53,ip4:0.0.0.0
        icmp:-1,-1,ip4:0.0.0.0"
        )
      }

      let(:empty_secg) {Fabricate(:secg)}
      let(:multi_port_secg) {Fabricate(:secg, rule: "
        tcp:10,80,ip4:0.0.0.0
      ")}

      it "Applies security group rules" do
      handler.init_vnic(vnic_id)

      nfa(host).should have_applied_vnic(vnic).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnic]).with_rules([
        "-p tcp -s 0.0.0.0/0 --dport 22 -j ACCEPT",
        "-p tcp -s 0.0.0.0/0 --dport 80 -j ACCEPT",
        "-p udp -s 0.0.0.0/0 --dport 53 -j ACCEPT",
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ])

      handler.destroy_vnic(vnic_id)
      vnic.destroy

      nfa(host).should_not have_applied_vnic(vnic)
      nfa(host).should_not have_applied_secg(secg)
      nfa(host).should have_nothing_applied
      end

      it "does live security switching and updates rules" do
        handler.init_vnic(vnic_id)

        nfa(host).should have_applied_vnic(vnic).with_secgs([secg])
        nfa(host).should have_applied_secg(secg).with_vnics([vnic]).with_rules([
          "-p tcp -s 0.0.0.0/0 --dport 22 -j ACCEPT",
          "-p tcp -s 0.0.0.0/0 --dport 80 -j ACCEPT",
          "-p udp -s 0.0.0.0/0 --dport 53 -j ACCEPT",
          "-p icmp -s 0.0.0.0/0 -j ACCEPT"
        ])

        handler.remove_sgs_from_vnic(vnic_id,[secg.canonical_uuid])
        handler.add_sgs_to_vnic(vnic_id,[empty_secg.canonical_uuid])

        nfa(host).should have_applied_vnic(vnic).with_secgs([empty_secg])
        nfa(host).should have_applied_secg(empty_secg).with_vnics([vnic]).with_rules([])
        nfa(host).should_not have_applied_secg(secg)

        handler.remove_sgs_from_vnic(vnic_id, [empty_secg.canonical_uuid])
        handler.add_sgs_to_vnic(vnic_id, [secg.canonical_uuid, multi_port_secg.canonical_uuid])

        nfa(host).should_not have_applied_secg(empty_secg)
        nfa(host).should have_applied_vnic(vnic).with_secgs([secg, multi_port_secg])
        nfa(host).should have_applied_secg(secg).with_vnics([vnic]).with_rules([
          "-p tcp -s 0.0.0.0/0 --dport 22 -j ACCEPT",
          "-p tcp -s 0.0.0.0/0 --dport 80 -j ACCEPT",
          "-p udp -s 0.0.0.0/0 --dport 53 -j ACCEPT",
          "-p icmp -s 0.0.0.0/0 -j ACCEPT"
        ])
        nfa(host).should have_applied_secg(multi_port_secg).with_vnics([vnic]).with_rules([
          "-p tcp -s 0.0.0.0/0 --dport 10:80 -j ACCEPT"
        ])
      end
    end
  end
end
