# -*- coding: utf-8 -*-

require 'spec_helper'

feature 'vnet_isolation' do
  let(:network_params) {{
    :network => "10.105.0.0",
    :gw => "10.105.0.1",
    :prefix => 24,
    :metric => 10,
    :domain_name => "vdclocal",
    :network_mode => "l2overlay",
    :ip_assignment => "asc",
    :service_type => "std",
    :display_name => "test",
    :dhcp_range => "default",
    :service_dhcp => "10.105.0.1",
    :dc_network => "dcn-cnb31y4y",
  }}

  let(:instance_params) {{
    :image_id => "wmi-centos1d64",
    :image_id_lbnode => "wmi-lbnode1d64",
    :cpu_cores => 1,
    :hypervisor => "kvm",
    :memory_size => 1024,
    :ssh_key_id => "ssh-demo",
  }}

  scenario "creates a network and an instance" do
    network = Mussel::Network.create(network_params)
    instance_1 = Mussel::Instance.create(instance_params.merge(
      :vifs => "{'eth0':{'index':'0','network':'#{network['id']}'}}"
    ))

    #expect(instance_1.ssh_to(instance_2)).to eq true
    expect(network).not_to eq nil
  end
end

