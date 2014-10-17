# -*- coding: utf-8 -*-

require 'spec_helper'

feature 'Basic Virtual Network Operations' do

  before(:all) do
  end

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
    pending 'need to ping instance over natted network'
    fail
    create_virtual_network_nw_demo1
    launch_instance
    confirm_instance_with_expected_configuration
    terminate_instance
    delete_virtual_network
  end

  scenario 'Virtual network can not be deleted if there is instance' do
    pending 'it is possible to delete networks atm'
    fail
    create_virtual_network_nw_demo1
    launch_instance
    network_delete_fail_if_instance_exist
    terminate_instance
    delete_virtual_network
  end

  scenario 'Instance works properly after restart (PowerOff/PowerOn)' do
    pending 'unable to ssh to instance through management line'
    fail
    create_virtual_network_nw_demo1
    launch_instance
    ssh_to_instance
    power_off_instance
    power_on_instance
    ssh_to_instance
    terminate_instance
    delete_virtual_network
  end

  scenario 'Change instance IP address of primary insterface' do
    pending 'not implemented, yet.'
    fail
    create_virtual_network_nw_demo1
    launch_instance
    confirm_instance_ipv4_address
    power_off_instance
    change_instance_ipv4_address
    power_on_instance
    confirm_instance_ipv4_address
    terminate_instance
    delete_virtual_network
  end

  let(:nw_manage) do
    Mussel::Network.index.select do |n|
      n.dc_network['name'] == config[:dc_network][:management]
    end.first
  end

  let(:dc_network) do
    dcn = Mussel::DcNetwork.index.select {|i| i.name == config[:dc_network][:vnet]}
    if dcn.empty?
      d = Mussel::DcNetwork.create({:name => config[:dc_network][:vnet]})
      Mussel::DcNetwork.add_offering_modes(d.id, {:mode => 'l2overlay'})
      dcn << Mussel::DcNetwork.update(d.id, {:allow_new_networks => true})
    end
    dcn.first
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

  def confirm_instance_with_expected_configuration
    expect(@instance.vif.first).not_to eq nil
    expect(@instance.vif.first['network_id']).to eq @network.id
  end

  def network_delete_fail_if_instance_exist
    Mussel::Network.destroy(@network.id)
    net = Mussel::Network.index.select {|n| n.uuid == @network.id }
    expect(net.empty?).to eq true
  end

  # TODO refactor

  def power_off_instance
    Mussel::Instance.power_off(@instance)

    i = nil
    loop do
      i = Mussel::Instance.show(@instance.id)
      p "instance state: #{i.state}"
      break if i.state == 'halted'
      sleep(1)
    end

    expect(i.state).to eq 'halted'
  end

  def power_on_instance
    Mussel::Instance.power_on(@instance)

    i = nil
    loop do
      i = Mussel::Instance.show(@instance.id)
      p "instance state: #{i.state}"
      break if i.state == 'running'
      sleep(1)
    end

    expect(i.state).to eq 'running'
  end

  def confirm_instance_ipv4_address
    ip = nil
    Net::SSH.start(ip, 'root', :keys => [@key_files[@instance.id]]) do |ssh|
      ip = ssh.exec!("ifconfig eth0 | grep 'inet addr:' | sed -e 's/^.*inet addr://' -e 's/ .*//'")
    end
    expect(ip).to eq '10.105.0.2'
  end

  def change_instance_ipv4_address
    # TODO create endpoint to change instance ipv4 address
  end
end
