# -*- coding: utf-8 -*-

require 'dcmgr_spec'

include DcmgrSpec::Netfilter
include DcmgrSpec::Fabricators

describe "SGHandler and NetfilterHandler" do
  context "on multiple hosts" do
    let(:secgA) { Fabricate(:secg) }
    let(:secgB) {
      Fabricate(:secg, rule:"tcp:22,22,#{secgA.canonical_uuid}")
    }

    let(:network) { Fabricate(:network) }
    let(:hostA) { Fabricate(:host_node, node_id: "hva.hostA") }
    let(:hostB) { Fabricate(:host_node, node_id: "hva.hostB") }

    let(:hostA_vnic1) { create_vnic(hostA, [secgA], "525400033c48", network, "10.0.0.1") }
    let(:hostA_vnic2) { create_vnic(hostA, [secgB], "525400033c49", network, "10.0.0.2") }
    let(:hostB_vnic1) { create_vnic(hostB, [secgA], "525400033c4a", network, "10.0.0.3") }
    let(:hostB_vnic2) { create_vnic(hostB, [secgB], "525400033c4b", network, "10.0.0.4") }

    let(:hostA_vnic1_id) { hostA_vnic1.canonical_uuid }
    let(:hostA_vnic2_id) { hostA_vnic2.canonical_uuid }
    let(:hostB_vnic1_id) { hostB_vnic1.canonical_uuid }
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

      expect(nfa(hostA)).to have_applied_vnic(hostA_vnic1).with_secgs([secgA])
      expect(nfa(hostB)).to have_applied_vnic(hostB_vnic1).with_secgs([secgA])

      # It's secgB that should apply the reference rules. Not secgA
      expect(nfa(hostA)).to have_applied_secg(secgA).with_vnics([hostA_vnic1, hostB_vnic1]).with_referencees([]).with_reference_rules([])
      expect(nfa(hostB)).to have_applied_secg(secgA).with_vnics([hostA_vnic1, hostB_vnic1]).with_referencees([]).with_reference_rules([])

      handler.init_vnic(hostA_vnic2_id)

      expect(nfa(hostA)).to have_applied_vnic(hostA_vnic2).with_secgs([secgB])

      expect(nfa(hostA)).to have_applied_secg(secgA).with_vnics([hostA_vnic1, hostB_vnic1]).with_referencees([]).with_reference_rules([])
      expect(nfa(hostB)).to have_applied_secg(secgA).with_vnics([hostA_vnic1, hostB_vnic1]).with_referencees([]).with_reference_rules([])

      expect(nfa(hostA)).to have_applied_secg(secgB).with_vnics([hostA_vnic2]).with_referencees([hostA_vnic1, hostB_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.3 --dport 22 -j ACCEPT"
      ])
      expect(nfa(hostB)).not_to have_applied_secg(secgB)

      handler.remove_sgs_from_vnic(hostB_vnic1_id, [secgA.canonical_uuid])
      handler.add_sgs_to_vnic(hostB_vnic1_id, [secgB.canonical_uuid])
      # hostA_vnic1 => secgA
      # hostA_vnic2 => secgB
      # hostB_vnic1 => secgB

      expect(nfa(hostA)).to have_applied_secg(secgB).with_vnics([hostA_vnic2, hostB_vnic1]).with_referencees([hostA_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT"
      ])
      expect(nfa(hostB)).to have_applied_secg(secgB).with_vnics([hostA_vnic2, hostB_vnic1]).with_referencees([hostA_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT"
      ])

      expect(nfa(hostA)).to have_applied_secg(secgA).with_vnics([hostA_vnic1]).with_referencees([]).with_reference_rules([])
      expect(nfa(hostB)).not_to have_applied_secg(secgA)

      handler.remove_sgs_from_vnic(hostA_vnic2_id, [secgB.canonical_uuid])
      handler.add_sgs_to_vnic(hostA_vnic2_id, [secgA.canonical_uuid])
      # hostA_vnic1 => secgA
      # hostA_vnic2 => secgA
      # hostB_vnic1 => secgB

      expect(nfa(hostA)).not_to have_applied_secg(secgB)
      expect(nfa(hostB)).to have_applied_secg(secgB).with_referencees([hostA_vnic1, hostA_vnic2]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.2 --dport 22 -j ACCEPT"
      ])

      expect(nfa(hostA)).to have_applied_secg(secgA).with_vnics([hostA_vnic1, hostA_vnic2]).with_referencees([]).with_reference_rules([])
      expect(nfa(hostB)).not_to have_applied_secg(secgA)

      # After we restart the host nodes, their netfilter stuff should still be the same
      nfa(hostA).flush
      nfa(hostB).flush
      handler.init_host(hostA.node_id)
      handler.init_host(hostB.node_id)

      expect(nfa(hostA)).not_to have_applied_secg(secgB)
      expect(nfa(hostB)).to have_applied_secg(secgB).with_referencees([hostA_vnic1, hostA_vnic2]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.2 --dport 22 -j ACCEPT"
      ])

      expect(nfa(hostA)).to have_applied_secg(secgA).with_vnics([hostA_vnic1, hostA_vnic2]).with_referencees([]).with_reference_rules([])
      expect(nfa(hostB)).not_to have_applied_secg(secgA)

      expect(nfa(hostA)).to have_applied_vnic(hostA_vnic1).with_secgs([secgA])
      expect(nfa(hostA)).to have_applied_vnic(hostA_vnic2).with_secgs([secgA])
      expect(nfa(hostA)).not_to have_applied_vnic(hostB_vnic1)

      expect(nfa(hostB)).to have_applied_vnic(hostB_vnic1).with_secgs([secgB])
      expect(nfa(hostB)).not_to have_applied_vnic(hostA_vnic1)
      expect(nfa(hostB)).not_to have_applied_vnic(hostA_vnic2)
    end

    it "removes ref rules when destroying a vnic" do
      handler.init_vnic(hostA_vnic2_id)
      handler.init_vnic(hostA_vnic1_id)
      handler.init_vnic(hostB_vnic1_id)

      expect(nfa(hostA)).to have_applied_secg(secgB).with_referencees([hostA_vnic1, hostB_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p tcp -s 10.0.0.3 --dport 22 -j ACCEPT"
      ])

      handler.destroy_vnic(hostB_vnic1_id, true)

      expect(nfa(hostA)).to have_applied_secg(secgB).with_referencees([hostA_vnic1]).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT"
      ])
    end

    it "handles ref rules when updating security group rules" do
      handler.init_vnic(hostA_vnic2_id)
      handler.init_vnic(hostA_vnic1_id)
      handler.init_vnic(hostB_vnic1_id)

      secgB.rule = "icmp:-1,-1,#{secgA.canonical_uuid}"; secgB.save
      handler.update_sg_rules(secgB.canonical_uuid)

      expect(nfa(hostA)).to have_applied_secg(secgB).with_referencees([hostA_vnic1, hostB_vnic1]).with_reference_rules([
        "-p icmp -s 10.0.0.1 -j ACCEPT",
        "-p icmp -s 10.0.0.3 -j ACCEPT"
      ])

      secgB.rule = "icmp:-1,-1,ip4:0.0.0.0"; secgB.save
      handler.update_sg_rules(secgB.canonical_uuid)

      expect(nfa(hostA)).to have_applied_secg(secgB).with_referencees([]).with_reference_rules([]).with_rules([
        "-p icmp -s 0.0.0.0/0 -j ACCEPT"
      ])
    end

    let(:secgC) { Fabricate(:secg) }
    let(:secgD) { Fabricate(:secg, rule: "
      tcp:22,22,#{secgA.canonical_uuid}
      udp:53,53,#{secgC.canonical_uuid}"
    )}
    let(:hostA_vnic3) { create_vnic(hostA, [secgC], "525400033c4e", network, "10.0.0.5")}
    let(:hostB_vnic3) { create_vnic(hostB, [secgD], "525400033c4f", network, "10.0.0.6")}

    it "references multiple groups at the same time" do
      handler.init_vnic(hostA_vnic1_id)
      handler.init_vnic(hostA_vnic3.canonical_uuid)
      handler.init_vnic(hostB_vnic3.canonical_uuid)

      expect(nfa(hostB)).to have_applied_secg(secgD).with_vnics([hostB_vnic3]).with_referencees(
      [hostA_vnic1, hostA_vnic3]
      ).with_reference_rules([
        "-p tcp -s 10.0.0.1 --dport 22 -j ACCEPT",
        "-p udp -s 10.0.0.5 --dport 53 -j ACCEPT"
      ])

      secgD.rule = "udp:53,53,#{secgC.canonical_uuid}"
      secgD.save
      handler.update_sg_rules(secgD.canonical_uuid)

      expect(nfa(hostB)).to have_applied_secg(secgD).with_vnics([hostB_vnic3]).with_referencees(
      [hostA_vnic3]).with_reference_rules(["-p udp -s 10.0.0.5 --dport 53 -j ACCEPT"])
    end

    context "with two security groups that reference each other" do
      let(:secgE) { Fabricate(:secg) }
      let(:secgF) { Fabricate(:secg) }
      let(:hostA_vnic4) { create_vnic(hostA, [secgE, secgF], "525400033c50", network, "10.0.0.7")}
      let(:hostB_vnic4) { create_vnic(hostB, [secgE, secgF], "525400033c51", network, "10.0.0.8")}

      it "works with multiple security groups on the same vnic and multiple hosts" do
        secgE.rule = "tcp:22,22,#{secgF.canonical_uuid}"; secgE.save
        secgF.rule = "udp:53,53,#{secgE.canonical_uuid}"; secgF.save
        handler.init_vnic(hostA_vnic4.canonical_uuid)
        handler.init_vnic(hostB_vnic4.canonical_uuid)

        expect(nfa(hostA)).to have_applied_vnic(hostA_vnic4).with_secgs([secgE, secgF])
        expect(nfa(hostA)).to have_applied_secg(secgE).with_vnics([hostB_vnic4, hostA_vnic4]
        ).with_referencees([hostB_vnic4, hostA_vnic4]).with_reference_rules([
          "-p tcp -s 10.0.0.7 --dport 22 -j ACCEPT",
          "-p tcp -s 10.0.0.8 --dport 22 -j ACCEPT"
        ])
        expect(nfa(hostA)).to have_applied_secg(secgF).with_vnics([hostB_vnic4, hostA_vnic4]
        ).with_referencees([hostB_vnic4, hostA_vnic4]).with_reference_rules([
          "-p udp -s 10.0.0.7 --dport 53 -j ACCEPT",
          "-p udp -s 10.0.0.8 --dport 53 -j ACCEPT"
        ])

        expect(nfa(hostB)).to have_applied_vnic(hostB_vnic4).with_secgs([secgE, secgF])
        expect(nfa(hostB)).to have_applied_secg(secgE).with_vnics([hostB_vnic4, hostA_vnic4]
        ).with_referencees([hostB_vnic4, hostA_vnic4]).with_reference_rules([
          "-p tcp -s 10.0.0.7 --dport 22 -j ACCEPT",
          "-p tcp -s 10.0.0.8 --dport 22 -j ACCEPT"
        ])
        expect(nfa(hostB)).to have_applied_secg(secgF).with_vnics([hostB_vnic4, hostA_vnic4]
        ).with_referencees([hostB_vnic4, hostA_vnic4]).with_reference_rules([
          "-p udp -s 10.0.0.7 --dport 53 -j ACCEPT",
          "-p udp -s 10.0.0.8 --dport 53 -j ACCEPT"
        ])
      end
    end
  end
end
