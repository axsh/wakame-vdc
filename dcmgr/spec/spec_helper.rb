# -*- coding: utf-8 -*-
require 'rubygems'
require 'dcmgr'
require 'fabrication'
require 'database_cleaner'
require 'isono' # Isono is needed for adding host nodes to the database

RSpec.configure do |config|
  Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                  [File.expand_path('../config/dcmgr.conf', __FILE__)])
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

TEST_ACCOUNT="a-shpoolxx"

Fabricator(:host_node, class_name: Dcmgr::Models::HostNode) do
  display_name "test hva"
  node_id "hva.test"
  hypervisor "openvz"
  offering_cpu_cores 100
  offering_memory_size 409600
  arch "x86_64"
end

Fabricator(:instance, class_name: Dcmgr::Models::Instance) do
  account_id TEST_ACCOUNT
  hypervisor "openvz"
  host_node { Fabricate(:host_node) }
end

Fabricator(:vnic, class_name: Dcmgr::Models::NetworkVif) do
  device_index 0
  account_id TEST_ACCOUNT
  instance { Fabricate(:instance) }
  before_save {|vnic, trancients| Dcmgr::Models::MacLease.create({:mac_addr => vnic.mac_addr.hex}) }
end

Fabricator(:secg, class_name: Dcmgr::Models::SecurityGroup) do
  account_id TEST_ACCOUNT
end
