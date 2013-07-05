# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"
require_relative 'helper_classes'
require_relative 'custom_matchers'

describe "SGHandler and NetfilterAgent" do
  context "with 3 vnics, 1 host node, 3 security groups" do
    let!(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let!(:groupA) { Fabricate(:secg) }
    let!(:groupB) { Fabricate(:secg) }
    let!(:groupC) { Fabricate(:secg) }

    let!(:vnicA) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(groupA)
        n.add_security_group(groupB)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.1").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let!(:vnicB) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(groupC)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.2").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let!(:vnicC) do
      Fabricate(:vnic, mac_addr: "525400033c4a").tap do |n|
        n.add_security_group(groupB)
        n.add_security_group(groupC)
        n.network = network
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.3").to_i,
          :network_id => network.id,
          :network_vif_id => n.id
        })

        n.instance.host_node = host
        n.instance.save
      end
    end
    let(:vnicA_id) {vnicA.canonical_uuid}
    let(:vnicB_id) {vnicB.canonical_uuid}
    let(:vnicC_id) {vnicC.canonical_uuid}

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "applies all netfilter settings for a host when calling init_host" do
      handler.init_host(host.node_id)

      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA, groupB])
      nfa(host).should have_applied_vnic(vnicB).with_secgs([groupC])
      nfa(host).should have_applied_vnic(vnicC).with_secgs([groupB, groupC])

      nfa(host).should have_applied_secg(groupA).with_vnics([vnicA])
      nfa(host).should have_applied_secg(groupB).with_vnics([vnicA, vnicC])
      nfa(host).should have_applied_secg(groupC).with_vnics([vnicB, vnicC])
    end
  end
end
