# -*- coding: utf-8 -*-

require 'spec_helper'
require "ipaddr"
require_relative 'helper_classes'
require_relative 'custom_matchers'

describe "SGHandler and NetfilterAgent" do
  context "using network mode" do
    let(:secg) { Fabricate(:secg) }

    # No need to test mode "securitygroup". All the other specs are already doing this
    let(:network_pt) { Fabricate(:network, network_mode: "passthrough") }
    let(:network_l2o) { Fabricate(:network, network_mode: "l2overlay") }
    let(:host) { Fabricate(:host_node, node_id: "hva.hostA") }

    let(:vnic_pt) do
      Fabricate(:vnic, mac_addr: "525400033c49").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.network = network_pt
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.2").to_i,
          :network_id => n.network.id,
          :network_vif_id => n.id
        })

        n.instance.save
      end
    end

    let(:vnic_l2o) do
      Fabricate(:vnic, mac_addr: "525400033c4a").tap do |n|
        n.add_security_group(secg)
        n.instance.host_node = host
        n.network = network_l2o
        n.save

        Dcmgr::Models::NetworkVifIpLease.create({
          :ipv4 => IPAddr.new("10.0.0.3").to_i,
          :network_id => n.network.id,
          :network_vif_id => n.id
        })

        n.instance.save
      end
    end

    let(:handler) {
      SGHandlerTest.new.tap {|sgh|
        sgh.add_host(host)
      }
    }

    it "l2overlay" do
      handler.init_vnic(vnic_l2o.canonical_uuid)

      # Security groups are still applied. Vnics just don't jump to them.
      nfa(host).should have_applied_vnic(vnic_l2o).with_secgs([])
      nfa(host).should have_applied_secg(secg).with_vnics([vnic_l2o])

      handler.destroy_vnic(vnic_l2o.canonical_uuid)
      vnic_l2o.destroy
      nfa(host).should_not have_applied_vnic(vnic_l2o)
      nfa(host).should_not have_applied_secg(secg)
    end

    it "passthrough" do
      handler.init_vnic(vnic_pt.canonical_uuid)

      # Again security groups are still applied. The vnic just isn't and
      # therefore doesn't traverse the security group chains.
      nfa(host).should_not have_applied_vnic(vnic_pt)
      nfa(host).should have_applied_secg(secg).with_vnics([vnic_pt])

      handler.destroy_vnic(vnic_pt.canonical_uuid)
      vnic_pt.destroy

      nfa(host).should_not have_applied_vnic(vnic_pt)
      nfa(host).should_not have_applied_secg(secg)
    end
  end
end
