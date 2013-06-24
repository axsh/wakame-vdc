# -*- coding: utf-8 -*-

# include "fabrication"

# Fabricator(:vif, class_name Vnmgr::Models::NetworkVif) do
# end
require 'rubygems'
require 'dcmgr'
# require 'fabrication'
require 'database_cleaner'
require 'isono'

RSpec.configure do |config|
  Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                  [File.expand_path('../../config/dcmgr.conf', __FILE__)])
  Dcmgr.run_initializers("logger","sequel")

  config.color_enabled = true
  config.formatter = :documentation

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

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
    @chains[:l2] += chains[:l2]
    @chains[:l3] += chains[:l3]
    @chains
  end

  def remove_chains(chains)
    @chains ||= {:l2 => [],:l3 => []}
    @chains[:l2] -= chains[:l2]
    @chains[:l3] -= chains[:l3]
    @chains
  end
end

# Fabricator(:host, class_name: NetfilterAgentTest)

TEST_ACCOUNT="a-shpoolxx"

# Fabricator(:mac_range, class_name: Dcmgr::Models::MacRange) do
#   test_name = "demomacs"
#   vendor_id = 5395456
#   range_begin = 1
#   range_end = 16777215
# end

# Fabricator(:dhcp_range, class_name: Dcmgr::Models::DhcpRange) do
#   range_begin = "192.168.3.1"
#   range_end = "192.168.3.254"
# end

# Fabricator(:network, class_name: Dcmgr::Models::Network) do
#   display_name = "test_network1"
#   ipv4_network = "192.168.3.0"
#   prefix = 24
#   account_id = TEST_ACCOUNT
#   network_mode = "securitygroup"
#   add_dhcp_range(Fabricate(:dhcp_range))
# end

# Fabricator(:mac_lease, class_name: Dcmgr::Models::MacLease) do
#   mac_addr
# end

# Fabricator(:ip_lease, class_name: Dcmgr::Models::IpLease)

# Fabricator(:host, class_name: Dcmgr::Models::HostNode) do
#   node_id = "hva.test"
#   arch = "x86_64"
#   hypervisor = "openvz"
#   display_name = "test hva"
# end

# Fabricator(:instance, class_name: Dcmgr::Models::Instance) do
#   account_id = TEST_ACCOUNT
#   host_node = Fabricate(:host)
#   hypervisor = "openvz"
# end

# Fabricator(:vnic, class_name: Dcmgr::Models::NetworkVif) do
#   display_name = "test_vnic"
#   device_index = 0
#   mac_addr = "525400033c48"
#   account_id = TEST_ACCOUNT
#   instance
# end

describe "SGHandler and NetfilterAgent" do
  context "with 1 vnic, 1 host node, 1 security group" do
    # let(:host) {
    #   h = Fabricate(:host)
    #   h.stub("nf_agent") {NetfilterAgentTest.new}
    # }
    # let(:instance) {Fabricate(:instance) {|i| i.host_node host }}
    # let(:vnic) do
    #   Fabricate(:mac_lease, mac_addr: 0x525400033c48)
    #   Fabricate(:vnic, mac_addr: "525400033c48") do |v|
    #     v.instance instance
    #   #   v.instance (Fabricate(:instance) {|i| i.host_node Fabricate(:host) })
    #   end
    # end
    let(:nf_agent) {NetfilterAgentTest.new}
    let(:host) { h = Dcmgr::Models::HostNode.create({:node_id => "hva.test",:hypervisor => "openvz",
      :display_name=>"test hva", :offering_cpu_cores => 100, :offering_memory_size => 400000,
      :arch => "x86_64"})
      h
    }
    let(:instance) {Dcmgr::Models::Instance.create(
      {:account_id => TEST_ACCOUNT,:hypervisor => "openvz",:host_node => host}
    )}
    let(:vnic) {
      Dcmgr::Models::MacLease.create({:mac_addr => 0x525400033c48})

      Dcmgr::Models::NetworkVif.create({:device_index => 0, :mac_addr => "525400033c48",
        :account_id => TEST_ACCOUNT, :instance => instance
      }
    )}

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
        # "vdc_#{sg.canonical_uuid}_isolation",
      ]
      handler.get_netfilter_agent(host).chains[:l3].should eq([
        "vdc_#{vnic.canonical_uuid}_d",
        "vdc_#{vnic.canonical_uuid}_d_standard",
        "vdc_#{vnic.canonical_uuid}_d_isolation",
        "vdc_#{vnic.canonical_uuid}_d_referencees",
        "vdc_#{vnic.canonical_uuid}_d_security",
        # "vdc_#{sg.canonical_uuid}_security",
        # "vdc_#{sg.canonical_uuid}_isolation",
      ])

      handler.destroy_vnic(vnic.canonical_uuid)
      handler.get_netfilter_agent(host).chains[:l2].should be_empty
      handler.get_netfilter_agent(host).chains[:l3].should be_empty
    end

  end
end
