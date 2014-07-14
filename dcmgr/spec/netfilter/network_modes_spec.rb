# -*- coding: utf-8 -*-

require 'dcmgr_spec'

include DcmgrSpec::Netfilter
include DcmgrSpec::Fabricators

describe "SGHandler and NetfilterHandler" do
  context "using network mode" do
    let(:secg) { Fabricate(:secg) }

    # No need to test mode "securitygroup". All the other specs are already doing this
    let(:network_pt) { Fabricate(:network, network_mode: "passthrough") }
    let(:network_l2o) { Fabricate(:network, network_mode: "l2overlay") }
    let(:host) { Fabricate(:host_node, node_id: "hva.hostA") }

    let(:vnic_pt) { create_vnic(host, [secg], "525400033c49", network_pt, "10.0.0.2") }
    let(:vnic_l2o) { create_vnic(host, [secg], "525400033c4a", network_l2o, "10.0.0.3") }

    let(:handler) {
      SGHandlerTest.new.tap {|sgh|
        sgh.add_host(host)
      }
    }

    it "l2overlay" do
      handler.init_vnic(vnic_l2o.canonical_uuid)

      # Security groups are still applied. Vnics just don't jump to them.
      expect(nfa(host)).to have_applied_vnic(vnic_l2o).with_secgs([])
      expect(nfa(host)).to have_applied_secg(secg).with_vnics([vnic_l2o])

      handler.destroy_vnic(vnic_l2o.canonical_uuid, true)
      expect(nfa(host)).not_to have_applied_vnic(vnic_l2o)
      expect(nfa(host)).not_to have_applied_secg(secg)
    end

    it "passthrough" do
      handler.init_vnic(vnic_pt.canonical_uuid)

      # Again security groups are still applied. The vnic just isn't and
      # therefore doesn't traverse the security group chains.
      expect(nfa(host)).not_to have_applied_vnic(vnic_pt)
      expect(nfa(host)).to have_applied_secg(secg).with_vnics([vnic_pt])

      handler.destroy_vnic(vnic_pt.canonical_uuid, true)

      expect(nfa(host)).not_to have_applied_vnic(vnic_pt)
      expect(nfa(host)).not_to have_applied_secg(secg)
    end
  end
end
