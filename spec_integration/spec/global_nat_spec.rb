# -*- conding: utf-8 -*-

require 'spec_helper'

feature 'Global NAT' do
  before(:all) do
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
      metric: 9,
      domain_name: 'vnet',
      network_mode: 'l2overlay',
      ip_assignment: 'asc',
      service_type: "std",
      display_name: "test",
      dhcp_range: "default",
      dc_network: dc_network.id,
      editable: true
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

  scenario 'Attach a global IP to an interface' do
    create_virtual_network_nw_demo1
    add_external_ip_service_to_virtual_network
    launch_instance
    acquire_and_attach_global_ip
    instance_ping_8_8_8_8
    terminate_instance
  end

  scenario 'Detach a global IP from an interface' do
    pending 'not implemented yet.'
    fail
  end

  scenario 'Release fail if an IP is already assigned' do
    pending 'not implemented yet.'
    fail
  end

  scenario 'Release fail if all IPs run out' do
    pending 'not implemented yet.'
    fail
  end

  def acquire_and_attach_global_ip
    ipp_uuid = config[:ip_pool_uuid]
    ipp_params = {
      :network_id => config[:nw_global_uuid]
    }
    ip_pool = Mussel::IpPool.acquire(ipp_uuid, ipp_params)
    expect(ip_pool).not_to eq nil

    eip_params = {
      :ip_handle_id => ip_pool.ip_handle_id
    }
    vif = Mussel::NetworkVif.attach_external_ip(eip_params, @instance.vif.first['vif_id'])
    expect(vif).not_to eq nil
  end

  def instance_ping_8_8_8_8
    ret = ssh_to_instance do |ssh|
      ssh.exec!('ping -c 1 8.8.8.8')
      ssh.exec!('echo $?')
    end
    expect(ret).to eq 0
  end
end
