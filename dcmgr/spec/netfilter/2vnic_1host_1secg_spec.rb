# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"
require_relative 'helper_classes'
require_relative 'matchers/have_applied_vnic'
require_relative 'matchers/have_applied_secg'

describe "SGHandler and NetfilterAgent" do
  context "with 2 vnics, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }
    let(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let(:vnicA) { create_vnic(host, [secg], "525400033c48", network, "10.0.0.1") }
    let(:vnicB) { create_vnic(host, [secg], "525400033c49", network, "10.0.0.2") }

    let(:vnicA_id) {vnicA.canonical_uuid}
    let(:vnicB_id) {vnicB.canonical_uuid}

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      # Create vnic A
      handler.init_vnic(vnicA_id)
      nfa(host).should have_applied_vnic(vnicA).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnicA])

      # Create vnic B
      handler.init_vnic(vnicB_id)
      nfa(host).should have_applied_vnic(vnicA).with_secgs([secg])
      nfa(host).should have_applied_vnic(vnicB).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnicA, vnicB])

      # Destroy vnic A
      handler.destroy_vnic(vnicA_id)
      vnicA.destroy
      nfa(host).should_not have_applied_vnic(vnicA)
      nfa(host).should have_applied_vnic(vnicB).with_secgs([secg])
      nfa(host).should have_applied_secg(secg).with_vnics([vnicB])

      # Destroy vnic B
      handler.destroy_vnic(vnicB_id)
      vnicB.destroy
      nfa(host).should have_nothing_applied
    end

    it "deletes isolation rules when destroying vnics" do
      handler.init_vnic(vnicA_id)
      handler.init_vnic(vnicB_id)

      nfa(host).should have_applied_secg(secg).with_vnics([vnicA, vnicB])

      handler.destroy_vnic(vnicB_id)
      vnicB.destroy

      nfa(host).should have_applied_secg(secg).with_vnics([vnicA])
    end
  end
end
