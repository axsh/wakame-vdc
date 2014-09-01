# -*- coding: utf-8 -*-

require 'spec_helper'

feature 'Basic Virtual Network Operations' do

  scenario 'Create and Delete virtual network' do
    create_virtual_network_nw_demo1
    confirm_network_parameters_through_wakame_vdc_api
    delete_virtual_network
  end

  scenario 'Confirm that set once parameters can not be changed' do
    pending 'not implemented, yet.'
    fail
  end

  scenario 'Create instance to virtual network (Dynamic IP address)' do
    pending 'not implemented, yet.'
    fail
  end

  scenario 'Create instance to virtual network (Static IP address)' do
    pending 'not implemented, yet.'
    fail
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

  let(:dc_network_params) do
    {
      name: 'vnettest',
      offering_network_mode: 'l2overlay',
      allow_new_network: 1
    }
  end

  let(:dc_network) do
    @dc_network || @dc_network = Mussel::DcNetwork.create(dc_network_params)
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

  def create_virtual_network_nw_demo1
    @network = Mussel::Network.create(nw_demo1_params)
  end

  def confirm_network_parameters_through_wakame_vdc_api
    expect(@network).not_to eq nil
  end

  def delete_virtual_network
    Mussel::Network.destroy(@network.id)
  end
end
