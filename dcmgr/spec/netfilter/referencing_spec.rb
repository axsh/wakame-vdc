# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"
require_relative 'helper_classes'
require_relative 'custom_matchers'

describe "SGHandler and NetfilterAgent" do
  context "on multiple hosts" do
    let(:secgA) { Fabricate(:secg) }
    let(:secgB) {
      Fabricate(:secg, rule:"tcp:22,22,#{secgA.canonical_uuid}")
    }

    let(:network) { Fabricate(:network) }
    let(:hostA) { Fabricate(:host_node, node_id: "hva.hostA") }
    let(:hostB) { Fabricate(:host_node, node_id: "hva.hostB") }
    let(:hostA_vnic1) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secgA)
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

    let(:hostA_vnic2) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(secgB)
        n.instance.host_node = hostA
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.2").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.save
      end
    end
    let(:hostA_vnic2_id) { hostA_vnic2.canonical_uuid }

    let(:hostB_vnic1) do
      Fabricate(:vnic, mac_addr: "525400033c4a").tap do |n|
        n.add_security_group(secgA)
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

    let(:hostB_vnic2) do
      Fabricate(:vnic, mac_addr: "525400033c4b").tap do |n|
        n.add_security_group(secgB)
        n.instance.host_node = hostB
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.4").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.save
      end
    end
    let(:hostB_vnic2_id) { hostB_vnic2.canonical_uuid }

    let(:handler) {
      SGHandlerTest.new.tap {|sgh|
        sgh.add_host(hostA)
        sgh.add_host(hostB)
      }
    }

    it "adds referencing rules" do
      # secgA => norules
      # secgB => "tcp:22,22,#{secgA.canonical_uuid}"
      # hostA_vnic1 => secgA 10.0.0.1
      # hostA_vnic2 => secgB 10.0.0.2
      # hostB_vnic1 => secgA 10.0.0.3
      handler.init_vnic(hostA_vnic1_id)
      handler.init_vnic(hostB_vnic1_id)

      nfa(hostA).should have_applied_vnic(hostA_vnic1).with_secgs([secgA])
      nfa(hostB).should have_applied_vnic(hostB_vnic1).with_secgs([secgA])

      # It's secgB that should apply the reference rules. Not secgA
      nfa(hostA).should have_applied_secg(secgA).with_vnics([hostA_vnic1, hostB_vnic1]).with_referencees([]).with_reference_rules([])
      nfa(hostB).should have_applied_secg(secgA).with_vnics([hostA_vnic1, hostB_vnic1]).with_referencees([]).with_reference_rules([])

      handler.init_vnic(hostA_vnic2_id)

      nfa(hostA).should have_applied_vnic(hostA_vnic2).with_secgs([secgB])

      nfa(hostA).should have_applied_secg(secgA).with_vnics([hostA_vnic1, hostB_vnic1]).with_referencees([]).with_reference_rules([])
      nfa(hostB).should have_applied_secg(secgA).with_vnics([hostA_vnic1, hostB_vnic1]).with_referencees([]).with_reference_rules([])

      nfa(hostA).should have_applied_secg(secgB).with_vnics([hostA_vnic2]).with_referencees([hostA_vnic1, hostB_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.3 --dport 22 -j ACCEPT"
      ])
      nfa(hostB).should_not have_applied_secg(secgB)

      handler.remove_sgs_from_vnic(hostB_vnic1_id, [secgA.canonical_uuid])
      handler.add_sgs_to_vnic(hostB_vnic1_id, [secgB.canonical_uuid])
      # hostA_vnic1 => secgA
      # hostA_vnic2 => secgB
      # hostB_vnic1 => secgB

      nfa(hostA).should have_applied_secg(secgB).with_vnics([hostA_vnic2, hostB_vnic1]).with_referencees([hostA_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT"
      ])
      nfa(hostB).should have_applied_secg(secgB).with_vnics([hostA_vnic2, hostB_vnic1]).with_referencees([hostA_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT"
      ])

      nfa(hostA).should have_applied_secg(secgA).with_vnics([hostA_vnic1]).with_referencees([]).with_reference_rules([])
      nfa(hostB).should_not have_applied_secg(secgA)

      handler.remove_sgs_from_vnic(hostA_vnic2_id, [secgB.canonical_uuid])
      handler.add_sgs_to_vnic(hostA_vnic2_id, [secgA.canonical_uuid])
      # hostA_vnic1 => secgA
      # hostA_vnic2 => secgA
      # hostB_vnic1 => secgB

      nfa(hostA).should_not have_applied_secg(secgB)
      nfa(hostB).should have_applied_secg(secgB).with_referencees([hostA_vnic1, hostA_vnic2]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.2 --dport 22 -j ACCEPT"
      ])

      nfa(hostA).should have_applied_secg(secgA).with_vnics([hostA_vnic1, hostA_vnic2]).with_referencees([]).with_reference_rules([])
      nfa(hostB).should_not have_applied_secg(secgA)

      # After we restart the host nodes, their netfilter stuff should still be the same
      nfa(hostA).flush
      nfa(hostB).flush
      handler.init_host(hostA.node_id)
      handler.init_host(hostB.node_id)

      nfa(hostA).should_not have_applied_secg(secgB)
      nfa(hostB).should have_applied_secg(secgB).with_referencees([hostA_vnic1, hostA_vnic2]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.2 --dport 22 -j ACCEPT"
      ])

      nfa(hostA).should have_applied_secg(secgA).with_vnics([hostA_vnic1, hostA_vnic2]).with_referencees([]).with_reference_rules([])
      nfa(hostB).should_not have_applied_secg(secgA)

      nfa(hostA).should have_applied_vnic(hostA_vnic1).with_secgs([secgA])
      nfa(hostA).should have_applied_vnic(hostA_vnic2).with_secgs([secgA])
      nfa(hostA).should_not have_applied_vnic(hostB_vnic1)

      nfa(hostB).should have_applied_vnic(hostB_vnic1).with_secgs([secgB])
      nfa(hostB).should_not have_applied_vnic(hostA_vnic1)
      nfa(hostB).should_not have_applied_vnic(hostA_vnic2)
    end

    #TODO: Add referencing to init_host
    #TODO: Check referencing when updating security group rules

    it "starts ref rules in the right secg" do
      handler.init_vnic(hostA_vnic1_id)
      handler.init_vnic(hostB_vnic2_id)

      nfa(hostA).should have_applied_secg(secgA).with_vnics([hostA_vnic1]).with_referencees([]).with_reference_rules([])
      nfa(hostB).should have_applied_secg(secgB).with_vnics([hostB_vnic2]).with_referencees([hostA_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT"
      ])
    end
  end
end
