# -*- coding: utf-8 -*-

require 'dcmgr_spec'

include DcmgrSpec::Netfilter
include DcmgrSpec::Fabricators

describe "SGHandler and NetfilterHandler" do
  context "with 2 vnics, 1 host node, 2 security groups" do
    let(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let(:groupA) { Fabricate(:secg) }; let(:groupA_id) {groupA.canonical_uuid}
    let(:groupB) { Fabricate(:secg) }; let(:groupB_id) {groupB.canonical_uuid}

    let(:vnicA) { create_vnic(host, [groupA], "525400033c48", network, "10.0.0.1") }
    let(:vnicB) { create_vnic(host, [groupB], "525400033c49", network, "10.0.0.2") }
    let(:vnicA_id) {vnicA.canonical_uuid}
    let(:vnicB_id) {vnicB.canonical_uuid}

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "should create and delete chains" do
      handler.init_vnic(vnicA_id)
      handler.init_vnic(vnicB_id)

      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])
      nfa(host).should have_applied_secg(groupA).with_vnics([vnicA])
      nfa(host).should have_applied_vnic(vnicB).with_secgs([groupB])
      nfa(host).should have_applied_secg(groupB).with_vnics([vnicB])

      handler.destroy_vnic(vnicB_id, true)

      nfa(host).should_not have_applied_vnic(vnicB)
      nfa(host).should_not have_applied_secg(groupB)
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])
      nfa(host).should have_applied_secg(groupA).with_vnics([vnicA])

      handler.destroy_vnic(vnicA_id, true)
      nfa(host).should have_nothing_applied
    end

    it "does live security group switching" do
      handler.init_vnic(vnicA_id)
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])

      handler.add_sgs_to_vnic(vnicA_id, [groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA, groupB])

      handler.remove_sgs_from_vnic(vnicA_id, [groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])

      # Nothing should change, nor should there be an error if we try to remove a group we're not in
      handler.remove_sgs_from_vnic(vnicA_id, [groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])

      # vnicA is already in groupA but that shouldn't be a problem. groupA should just be ignored. That's what we're testing here.
      handler.add_sgs_to_vnic(vnicA_id, [groupA_id, groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA, groupB])

      handler.remove_sgs_from_vnic(vnicA_id, [groupA_id, groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([])

      handler.add_sgs_to_vnic(vnicA_id, [groupA_id, groupB_id])
      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA, groupB])

      handler.destroy_vnic(vnicA_id, true)
      nfa(host).should have_nothing_applied
    end

    it "starts 2 vnics in the same secg, then moves one out" do
      handler.init_vnic(vnicA_id)

      # Put vnicB in the same group as vnicA before we make netfilter aware of it
      vnicB.remove_security_group(groupB)
      vnicB.add_security_group(groupA)
      handler.init_vnic(vnicB_id)

      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])
      nfa(host).should have_applied_vnic(vnicB).with_secgs([groupA])
      nfa(host).should have_applied_secg(groupA).with_vnics([vnicA, vnicB])

      handler.remove_sgs_from_vnic(vnicB_id, [groupA_id])
      handler.add_sgs_to_vnic(vnicB_id, [groupB_id])

      nfa(host).should have_applied_vnic(vnicA).with_secgs([groupA])
      nfa(host).should have_applied_vnic(vnicB).with_secgs([groupB])
      nfa(host).should have_applied_secg(groupA).with_vnics([vnicA])
      nfa(host).should have_applied_secg(groupB).with_vnics([vnicB])
    end
  end
end
