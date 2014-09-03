# -*- coding: utf-8 -*-

require 'spec_helper'

feature 'Basic Virtual Network Operations' do

  scenario 'Create and Delete virtual network' do
    create_virtual_network_nw_demo1
    confirm_network_parameters_through_wakame_vdc_api
    delete_virtual_network
  end

  scenario 'Confirm that set once parameters can not be changed' do
    create_virtual_network_nw_demo1
    confirm_parameter_immutability
    delete_virtual_network
  end

  scenario 'Create instance to virtual network (Dynamic IP address)' do
    pending 'Unsupported feature.'
    fail
  end

  scenario 'Create instance to virtual network (Static IP address)' do
    create_virtual_network_nw_demo1
    start_new_instance_with_ipv4_address_10_105_0_10
    confirm_instance_with_expected_configuration
    terminate_instance
    delete_virtual_network
  end

  scenario 'Virtual network can not be deleted if there is instance' do
    pending 'not implemented, yet.'
    fail
  end

  scenario 'Instance works properly after restart (PowerOff/PowerOn)' do
    pending 'not implemented, yet.'
    fail
  end

  scenario 'Change instance IP address of primary insterface' do
    pending 'not implemented, yet.'
    fail
  end

  let(:dc_network) do
    @dc_network || @dc_network = Mussel::DcNetwork.index.select {|i| i.name == 'vnet'}.first
  end

  let(:nw_demo1_params) do
    {
      network: '10.105.0.0',
      gw: '10.105.0.1',
      prefix: 24,
      metric: 10,
      domain_name: 'vnet',
      network_mode: 'l2overlay',
      ip_assignment: 'asc',
      service_type: "std",
      display_name: "test",
      dhcp_range: "default",
      service_dhcp: "10.105.0.1",
      dc_network: dc_network.id,
    }
  end

  let(:instance_params) do
    {
      image_id: "wmi-centos1d64",
      image_id_lbnode: "wmi-lbnode1d64",
      cpu_cores: 1,
      hypervisor: "kvm",
      memory_size: 1024
    }
  end

  def create_virtual_network_nw_demo1
    @network = Mussel::Network.create(nw_demo1_params)
  end

  def confirm_network_parameters_through_wakame_vdc_api
    expect(@network).not_to eq nil
    expect(@network.ipv4_network).to eq nw_demo1_params[:network]
    expect(@network.ipv4_gw).to eq nw_demo1_params[:gw]
  end

  def delete_virtual_network
    ret = Mussel::Network.destroy(@network.id)
    expect(ret.first).to eq @network.id
  end

  def confirm_parameter_immutability
    ret = Mussel::Network.update(@network.id, {network: '10.100.9.0'})
    expect(ret.id).to eq @network.id
    expect(ret.ipv4_network).not_to eq '10.100.9.0'
  end

  def start_new_instance_with_ipv4_address_10_105_0_10
    instance_params[:vifs] = {
      'eth0' => {'index'=>'0', 'network'=>@network.id, 'ipv4_addr'=>'10.105.0.10', 'mac_addr'=>'525400000001'}
    }

    setup_vif(instance_params)
    create_ssh_key_pair(instance_params)

    @instance = Mussel::Instance.create(instance_params)
  end

  def confirm_instance_with_expected_configuration
    expect(@instance.vifs.first).not_to eq nil
    expect(@instance.vifs.first['network']).to eq @network.id
    expect(@instance.vifs.first['ipv4_addr']).to eq '10.105.0.10'
  end

  def terminate_instance
    ret = Mussel::Instance.destroy(@instance)
    expect(ret.first).to eq @instance.id
  end
end
