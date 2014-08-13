# -*- coding: utf-8 -*-

shared_examples 'aws top level metadata' do
  it 'adds a bunch of general aws-like items describing the provided instance' do
    expect(items['ami-id']).to eq inst.image.canonical_uuid
    expect(items['hostname']).to eq inst.hostname
    expect(items['instance-action']).to eq inst.state
    expect(items['instance-id']).to eq inst.canonical_uuid
    expect(items['local-hostname']).to eq inst.hostname
    expect(items['public-hostname']).to eq inst.hostname
    expect(items['x-account-id']).to eq inst.account_id
  end
end

shared_examples 'aws metadata for instance without instance-spec in request params' do
  it 'uses Models::Image#instance_model_name for instance-type' do
    expect(items['instance-type']).to eq inst.image.instance_model_name
  end
end

shared_examples 'aws metadata for instance with vnics' do
  it 'sets \'mac\' to the mac address of the first vnic' do
    expect(items['mac']).to eq inst.nic.first.pretty_mac_addr
  end
end

shared_examples 'aws metadata for instance with ip leases' do
  def nic_item(nic, item)
    items["network/interfaces/macs/#{nic.pretty_mac_addr('-')}/#{item}"]
  end

  it 'sets \'local-ipv4\' to the first ip lease of the first vnic' do
    expect(items['local-ipv4']).to eq inst.nic.first.ip.first.ipv4_s
  end

  #TODO: Nat tests?

  it 'adds aws metadata for every vnic that the instance has' do
    inst.nic.each do |n|
      security_groups = n.security_groups.map { |sg| sg.canonical_uuid }.join(' ')
      first_direct_ip = n.direct_ip_lease.first
      ipv4_network = n.network.ipv4_ipaddress

      #
      # Standard AWS stuff
      #
      expect(nic_item(n, 'local-hostname')).to eq inst.hostname
      # It adds *only* the first ip lease of every vnic!
      expect(nic_item(n, 'local-ipv4s')).to eq first_direct_ip.ipv4
      expect(nic_item(n, 'mac')).to eq n.pretty_mac_addr
      expect(nic_item(n, 'security-groups')).to eq security_groups

      #
      # Wakame extensions
      #
      expect(nic_item(n, 'x-dns')).to eq n.network.dns_server
      expect(nic_item(n, 'x-gateway')).to eq n.network.ipv4_gw
      expect(nic_item(n, 'x-netmask')).to eq ipv4_network.netmask
      expect(nic_item(n, 'x-network')).to eq ipv4_network.to_s
      expect(nic_item(n, 'x-broadcast')).to eq ipv4_network.broadcast.to_s
      expect(nic_item(n, 'x-metric')).to eq n.network.metric
    end
  end
end

shared_examples 'aws metadata for instance without ip leases' do
  it 'has no ip related metadata' do
    expect(items['local-ipv4']).to be nil
    expect(items['public-ipv4']).to be nil
  end

  it 'has no network/interfaces/* metadata entries' do
    expect(nic_items).to be_empty
  end
end

shared_examples 'aws metadata for instance without ssh keypair' do
  it 'has no ssh key related metadata' do
    expect(items['public-keys/']).to be nil
    expect(items['public-keys/0']).to be nil
    expect(items['public-keys/0/openssh-key']).to be nil
  end
end

