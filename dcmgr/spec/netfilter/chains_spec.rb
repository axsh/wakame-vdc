# -*- coding: utf-8 -*-

require 'spec_helper'

class SGHandlerTest
  include Dcmgr::Logger
  include Dcmgr::VNet::SGHandler

  def add_host(hn)
    @hosts ||= {}
    raise "Host already exists: #{hn.canonical_uuid}" if @hosts[hn.canonical_uuid]
    @hosts[hn.canonical_uuid] = NetfilterAgentTest.new
  end

  def get_netfilter_agent(hn)
    @hosts[hn.canonical_uuid]
  end

  def call_packetfilter_service(hn,method,*args)
    @hosts[hn.canonical_uuid].send(method,*args)
  end
end

class NetfilterAgentTest
  include Dcmgr::Logger
  include Dcmgr::VNet::Netfilter::NetfilterAgent
  attr_reader :chains

  def create_chains(chains)
    @chains ||= {:l2 => [],:l3 => []}
    chains[:l2] ||= []; chains[:l3] ||= []
    @chains[:l2] += chains[:l2]
    @chains[:l3] += chains[:l3]
    @chains
  end

  def remove_chains(chains)
    @chains ||= {:l2 => [],:l3 => []}
    chains[:l2] ||= []; chains[:l3] ||= []
    @chains[:l2] -= chains[:l2]
    @chains[:l3] -= chains[:l3]
    @chains
  end
end

def l2_chains_for_vnic(vnic_id)
  [
    "vdc_#{vnic.canonical_uuid}_d",
    "vdc_#{vnic.canonical_uuid}_d_standard",
    "vdc_#{vnic.canonical_uuid}_d_isolation",
    "vdc_#{vnic.canonical_uuid}_d_referencers"
  ]
end

def l2_chains_for_secg(secg_id)
  ["vdc_#{secg.canonical_uuid}_isolation"]
end

def l3_chains_for_vnic(vnic_id)
  [
    "vdc_#{vnic.canonical_uuid}_d",
    "vdc_#{vnic.canonical_uuid}_d_standard",
    "vdc_#{vnic.canonical_uuid}_d_isolation",
    "vdc_#{vnic.canonical_uuid}_d_referencees",
    "vdc_#{vnic.canonical_uuid}_d_security",
  ]
end

def l3_chains_for_secg(secg_id)
  [
    "vdc_#{secg.canonical_uuid}_security",
    "vdc_#{secg.canonical_uuid}_isolation"
  ]
end

describe "SGHandler and NetfilterAgent" do
  context "with 1 vnic, 1 host node, 1 security group" do
    let(:secg) { Fabricate(:secg) }

    let(:vnic) do
      Fabricate(:vnic, mac_addr: "525400033c48").tap do |n|
        n.add_security_group(secg)
      end
    end

    let(:handler) {SGHandlerTest.new}

    it "should create and delete chains" do
      host = vnic.instance.host_node
      handler.add_host(host)
      handler.init_vnic(vnic.canonical_uuid)

      handler.get_netfilter_agent(host).chains[:l2].should eq(
        l2_chains_for_vnic(vnic.canonical_uuid) + l2_chains_for_secg(secg.canonical_uuid)
      )
      handler.get_netfilter_agent(host).chains[:l3].should eq(
        l3_chains_for_vnic(vnic.canonical_uuid) + l3_chains_for_secg(secg.canonical_uuid)
      )

      handler.destroy_vnic(vnic.canonical_uuid)
      handler.get_netfilter_agent(host).chains[:l2].should be_empty
      handler.get_netfilter_agent(host).chains[:l3].should be_empty
    end
  end

end
