# -*- coding: utf-8 -*-

require 'dcmgr_spec'

include DcmgrSpec::Netfilter
include DcmgrSpec::Fabricators

describe "SGHandler and NetfilterHandler" do

  context "With an instance with multiple vnics" do
    let(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let(:groupA) { Fabricate(:secg) }; let(:groupA_id) {groupA.canonical_uuid}

    let(:inst) { Fabricate(:instance, host_node: host) }

    let!(:vnicA) do
      create_vnic(host, [groupA], "525400033c48", network, "10.0.0.1").tap do |n|
        n.instance = inst
        n.save_changes
      end
    end

    let!(:vnicB) do
      create_vnic(host, [groupA], "525400033c49", network, "10.0.0.2").tap do |n|
        n.instance = inst
        n.save_changes
      end
    end

    let(:vnicA_id) {vnicA.canonical_uuid}
    let(:vnicB_id) {vnicB.canonical_uuid}

    let(:handler) { SGHandlerTest.new.tap { |sgh| sgh.add_host(host) } }

    it "is able to one interface without touching groups on the other" do
      handler.init_vnic(vnicA_id)
      handler.init_vnic(vnicB_id)

      expect(nfa(host)).to have_applied_vnic(vnicA).with_secgs([groupA])
      expect(nfa(host)).to have_applied_secg(groupA).with_vnics([vnicA, vnicB])
      expect(nfa(host)).to have_applied_vnic(vnicB).with_secgs([groupA])
      expect(nfa(host)).to have_applied_secg(groupA).with_vnics([vnicA, vnicB])

      handler.destroy_vnic(vnicA_id, true)
      expect(nfa(host)).to have_applied_vnic(vnicB).with_secgs([groupA])
      expect(nfa(host)).to have_applied_secg(groupA).with_vnics([vnicB])
    end
  end
end
