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

TEST_ACCOUNT="a-shpoolxx"

describe "SGHandler and NetfilterAgent" do
  context "with 1 vnic, 1 host node, 1 security group" do
    let(:nf_agent) {NetfilterAgentTest.new}
    let(:host) { h = Dcmgr::Models::HostNode.create({:node_id => "hva.test",:hypervisor => "openvz",
      :display_name=>"test hva", :offering_cpu_cores => 100, :offering_memory_size => 400000,
      :arch => "x86_64"})
      h
    }
    let(:instance) {Dcmgr::Models::Instance.create(
      {:account_id => TEST_ACCOUNT,:hypervisor => "openvz",:host_node => host}
    )}
    let(:secg) {Dcmgr::Models::SecurityGroup.create(:account_id => TEST_ACCOUNT)}
    let(:vnic) {
      Dcmgr::Models::MacLease.create({:mac_addr => 0x525400033c48})

      nic = Dcmgr::Models::NetworkVif.create({:device_index => 0, :mac_addr => "525400033c48",
        :account_id => TEST_ACCOUNT, :instance => instance
      })
      nic.add_security_group(secg)
      nic
    }

    let(:handler) do
      SGHandlerTest.new
    end

    it "should create and delete chains" do
      handler.add_host(host)
      handler.init_vnic(vnic.canonical_uuid)

      handler.get_netfilter_agent(host).chains[:l2].should == [
        "vdc_#{vnic.canonical_uuid}_d",
        "vdc_#{vnic.canonical_uuid}_d_standard",
        "vdc_#{vnic.canonical_uuid}_d_isolation",
        "vdc_#{vnic.canonical_uuid}_d_referencers",
        "vdc_#{secg.canonical_uuid}_isolation",
      ]
      handler.get_netfilter_agent(host).chains[:l3].should eq([
        "vdc_#{vnic.canonical_uuid}_d",
        "vdc_#{vnic.canonical_uuid}_d_standard",
        "vdc_#{vnic.canonical_uuid}_d_isolation",
        "vdc_#{vnic.canonical_uuid}_d_referencees",
        "vdc_#{vnic.canonical_uuid}_d_security",
        "vdc_#{secg.canonical_uuid}_security",
        "vdc_#{secg.canonical_uuid}_isolation",
      ])

      handler.destroy_vnic(vnic.canonical_uuid)
      handler.get_netfilter_agent(host).chains[:l2].should be_empty
      handler.get_netfilter_agent(host).chains[:l3].should be_empty
    end

  end
end
