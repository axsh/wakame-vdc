# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"
require_relative 'helper_classes'
require_relative 'custom_matchers'

describe "SGHandler and NetfilterAgent" do
  context "with 1 vnic, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }
    let(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let(:vnic) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
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
  end
end
