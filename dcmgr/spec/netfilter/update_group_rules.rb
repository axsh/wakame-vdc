# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"
require_relative 'helper_classes'
require_relative 'custom_matchers'

describe "SGHandler and NetfilterAgent" do
  context "on multiple hosts" do
    let(:secg) { Fabricate(:secg, rule:"
      # demo rule for demo instances
      tcp:22,22,ip4:0.0.0.0
      tcp:80,80,ip4:0.0.0.0
      udp:53,53,ip4:0.0.0.0
      icmp:-1,-1,ip4:0.0.0.0
    ") }

    let(:network) { Fabricate(:network) }
    let(:hostA) { Fabricate(:host_node, node_id: "hva.hostA") }
    let(:hostB) { Fabricate(:host_node, node_id: "hva.hostB") }
    let(:hostA_vnic1) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = hostA
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.1").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.save
      end
    end
    let(:hostA_vnic1_id) { hostA_vnic1.canonical_uuid }

    let(:hostB_vnic1) do
      Fabricate(:vnic, mac_addr: "525400033c4a").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = hostB
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.3").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.save
      end
    end
    let(:hostB_vnic1_id) { hostB_vnic1.canonical_uuid }

    let(:handler) {
      SGHandlerTest.new.tap {|sgh|
        sgh.add_host(hostA)
        sgh.add_host(hostB)
      }
    }

    it "updates group rules on all hosts" do
      handler.init_vnic(hostA_vnic1_id)
      handler.init_vnic(hostB_vnic1_id)

      nfa(hostA).should have_applied_secg(secg).with_rules([
        "-p tcp -s 0.0.0.0/0 --dport 22 -j ACCEPT",
        "-p tcp -s 0.0.0.0/0 --dport 80 -j ACCEPT",
        "-p udp -s 0.0.0.0/0 --dport 53 -j ACCEPT",
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ])
      nfa(hostB).should have_applied_secg(secg).with_rules([
        "-p tcp -s 0.0.0.0/0 --dport 22 -j ACCEPT",
        "-p tcp -s 0.0.0.0/0 --dport 80 -j ACCEPT",
        "-p udp -s 0.0.0.0/0 --dport 53 -j ACCEPT",
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ])

      secg.rule = "
        tcp:22,22,ip4:0.0.0.0
        udp:53,53,ip4:0.0.0.0
        icmp:-1,-1,ip4:0.0.0.0
      "
      secg.save
      handler.update_sg_rules(secg.canonical_uuid)

      nfa(hostA).should have_applied_secg(secg).with_rules([
        "-p tcp -s 0.0.0.0/0 --dport 22 -j ACCEPT",
        "-p udp -s 0.0.0.0/0 --dport 53 -j ACCEPT",
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ])
      nfa(hostB).should have_applied_secg(secg).with_rules([
        "-p tcp -s 0.0.0.0/0 --dport 22 -j ACCEPT",
        "-p udp -s 0.0.0.0/0 --dport 53 -j ACCEPT",
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ])

      secg.rule = "udp:53,53,ip4:8.8.8.8"
      secg.save
      handler.update_sg_rules(secg.canonical_uuid)

      nfa(hostA).should have_applied_secg(secg).with_rules([
        "-p udp -s 8.8.8.8/32 --dport 53 -j ACCEPT",
      ])
      nfa(hostB).should have_applied_secg(secg).with_rules([
        "-p udp -s 8.8.8.8/32 --dport 53 -j ACCEPT",
      ])

      secg.rule = ""
      secg.save
      handler.update_sg_rules(secg.canonical_uuid)
      nfa(hostA).should have_applied_secg(secg).with_rules([])
      nfa(hostB).should have_applied_secg(secg).with_rules([])
    end

  end
end
