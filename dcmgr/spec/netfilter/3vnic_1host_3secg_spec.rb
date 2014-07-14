# -*- coding: utf-8 -*-

require 'dcmgr_spec'

include DcmgrSpec::Netfilter
include DcmgrSpec::Fabricators

describe "SGHandler and NetfilterHandler" do
  context "with 3 vnics, 1 host node, 3 security groups" do
    let!(:host) { Fabricate(:host_node) }
    let(:network) { Fabricate(:network) }
    let!(:groupA) { Fabricate(:secg) }
    let!(:groupB) { Fabricate(:secg) }
    let!(:groupC) { Fabricate(:secg) }

    let!(:vnicA) { create_vnic(host, [groupA, groupB], "525400033c48", network, "10.0.0.1") }
    let!(:vnicB) { create_vnic(host, [groupC], "525400033c49", network, "10.0.0.2") }
    let!(:vnicC) { create_vnic(host, [groupB, groupC], "525400033c4a", network, "10.0.0.3") }

    let(:handler) {SGHandlerTest.new.tap{|sgh| sgh.add_host(host)}}

    it "applies all netfilter settings for a host when calling init_host" do
      handler.init_host(host.node_id)

      expect(nfa(host)).to have_applied_vnic(vnicA).with_secgs([groupA, groupB])
      expect(nfa(host)).to have_applied_vnic(vnicB).with_secgs([groupC])
      expect(nfa(host)).to have_applied_vnic(vnicC).with_secgs([groupB, groupC])

      expect(nfa(host)).to have_applied_secg(groupA).with_vnics([vnicA])
      expect(nfa(host)).to have_applied_secg(groupB).with_vnics([vnicA, vnicC])
      expect(nfa(host)).to have_applied_secg(groupC).with_vnics([vnicB, vnicC])
    end
  end
end
