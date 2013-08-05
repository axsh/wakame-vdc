# -*- coding: utf-8 -*-
require 'dcmgr_spec'
require 'fabrication'
require 'database_cleaner'
require 'isono' # Isono is needed for adding host nodes to the database


RSpec.configure do |config|
  Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                  [File.expand_path('../config/dcmgr.conf', __FILE__)])
  Dcmgr.run_initializers("logger", "sequel")

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

TEST_ACCOUNT="a-shpoolxx"

Fabricator(:host_node, class_name: Dcmgr::Models::HostNode) do
  display_name "test hva"
  node_id "hva.test"
  hypervisor "openvz"
  offering_cpu_cores 100
  offering_memory_size 409600
  arch "x86_64"

  after_create do |host, transients|
    Fabricate(:node_state, state: "online", node_id: host.node_id)
  end
end

Fabricator(:node_state, class_name: Isono::Models::NodeState)

Fabricator(:instance, class_name: Dcmgr::Models::Instance) do
  account_id TEST_ACCOUNT
  hypervisor "openvz"
end

Fabricator(:vnic, class_name: Dcmgr::Models::NetworkVif) do
  device_index 0
  account_id TEST_ACCOUNT
  instance { Fabricate(:instance) }
  before_save {|vnic, trancients| Dcmgr::Models::MacLease.create({:mac_addr => vnic.mac_addr.hex})}
end

Fabricator(:network, class_name: Dcmgr::Models::Network) do
  account_id TEST_ACCOUNT
  ipv4_network "10.0.0.0"
  prefix 24
  network_mode "securitygroup" # Ignored in this new version of netfilter
  service_type "std"
  display_name "test network"
end

Fabricator(:secg, class_name: Dcmgr::Models::SecurityGroup) do
  account_id TEST_ACCOUNT
end

def create_vnic(host, secgs, mac_addr, network, ipv4)
  Fabricate(:vnic, mac_addr: mac_addr).tap do |n|
    secgs.each {|sg| n.add_security_group(sg) }
    n.instance.host_node = host
    n.network = network
    n.save

    Dcmgr::Models::NetworkVifIpLease.create({
      :ipv4 => IPAddr.new(ipv4).to_i,
      :network_id => n.network.id,
      :network_vif_id => n.id
    })

    n.instance.save
  end
end
