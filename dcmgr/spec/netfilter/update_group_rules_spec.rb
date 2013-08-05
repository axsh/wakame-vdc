# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"
require_relative 'test_classes/netfilter_agent'
require_relative 'test_classes/sg_handler'
require_relative 'test_classes/nf_cmd_parser.rb'
require_relative 'matchers/have_applied_vnic'
require_relative 'matchers/have_applied_secg'

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

    let(:hostA_vnic1) { create_vnic(hostA, [secg], "525400033c48", network, "10.0.0.1") }
    let(:hostB_vnic1) { create_vnic(hostB, [secg], "525400033c4a", network, "10.0.0.3") }

    let(:hostB_vnic1_id) { hostB_vnic1.canonical_uuid }
    let(:hostA_vnic1_id) { hostA_vnic1.canonical_uuid }

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

    let(:secg_ref) { Fabricate(:secg) }

    let(:hostB_vnic2) { create_vnic(hostB, [secg_ref], "525400033c4c", network, "10.0.0.4") }
    let(:hostB_vnic2_id) { hostB_vnic2.canonical_uuid }

    it "updates reference rules on all hosts" do
      handler.init_vnic(hostA_vnic1_id)
      handler.init_vnic(hostB_vnic1_id)
      handler.init_vnic(hostB_vnic2_id)

      nfa(hostB).should have_applied_secg(secg_ref).with_rules([]).with_referencees([]).with_reference_rules([])

      secg_ref.rule = "tcp:22,22,#{secg.canonical_uuid}"
      secg_ref.save
      handler.update_sg_rules(secg_ref.canonical_uuid)

      nfa(hostB).should have_applied_secg(secg_ref).with_rules([]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.3 --dport 22 -j ACCEPT"
      ]).with_referencees([hostA_vnic1, hostB_vnic1])

      secg_ref.rule = "
        tcp:22,22,#{secg.canonical_uuid}
        icmp:-1,-1,ip4:0.0.0.0
      "
      secg_ref.save
      handler.update_sg_rules(secg_ref.canonical_uuid)

      nfa(hostB).should have_applied_secg(secg_ref).with_rules([
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.3 --dport 22 -j ACCEPT"
      ]).with_referencees([hostA_vnic1, hostB_vnic1])

      secg_ref.rule = "
        udp:53,53,#{secg.canonical_uuid}
        tcp:666,666,#{secg.canonical_uuid}
        icmp:-1,-1,ip4:0.0.0.0
      "
      secg_ref.save
      handler.update_sg_rules(secg_ref.canonical_uuid)

      nfa(hostB).should have_applied_secg(secg_ref).with_rules([
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ]).with_reference_rules([
        "-p udp -s 10.0.0.1 --dport 53 -j ACCEPT",
        "-p udp -s 10.0.0.3 --dport 53 -j ACCEPT",
        "-p tcp -s 10.0.0.1 --dport 666 -j ACCEPT",
        "-p tcp -s 10.0.0.3 --dport 666 -j ACCEPT"
      ]).with_referencees([hostA_vnic1, hostB_vnic1])

      secg_ref.rule = "
        icmp:-1,-1,ip4:0.0.0.0
      "
      secg_ref.save
      handler.update_sg_rules(secg_ref.canonical_uuid)
      nfa(hostB).should have_applied_secg(secg_ref).with_rules([
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ]).with_reference_rules([]).with_referencees([])

      secg_ref.rule = ""
      secg_ref.save
      handler.update_sg_rules(secg_ref.canonical_uuid)

      nfa(hostB).should have_applied_secg(secg_ref).with_rules([]).with_referencees([]).with_reference_rules([])
    end

  end
end
