# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/networks' do
  get do
    # description "List networks in account"
    # params start, fixnum, optional
    # params limit, fixnum, optional
    ds = M::Network.dataset

    if params[:account_id]
      ds = ds.filter(:account_id=>params[:account_id])
    end

    ds = datetime_range_params_filter(:created, ds)
    ds = datetime_range_params_filter(:deleted, ds)

    collection_respond_with(ds) do |paging_ds|
      R::NetworkCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description "Retrieve details about a network"
    # params :id required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?

    respond_with(R::Network.new(nw).generate)
  end

  post do
    # description "Create new network"
    # params :gw required default gateway address of the network
    # params :network required network address of the network
    # params :prefix optional  netmask bit length. it will be
    #               set 24 if none.
    # params :description optional description for the network
    savedata = {
      :account_id=>@account.canonical_uuid,
      :ipv4_gw => params[:gw],
      :ipv4_network => params[:network],
      :prefix => params[:prefix].to_i,
      :description => params[:description],
    }
    nw = M::Network.create(savedata)

    respond_with(R::Network.new(nw).generate)
  end

  delete '/:id' do
    # description "Remove network information"
    # params :id required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    nw.destroy

    response_to([nw.canonical_uuid])
  end

  put '/:id/dhcp/reserve' do
    # description 'Register reserved IP address to the network'
    # params id, string, required
    # params ipaddr, [String,Array], required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?

    (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
      nw.ip_lease_dataset.add_reserved(ip)
    }
    response_to({})
  end
  
  put '/:id/dhcp/release' do
    # description 'Unregister reserved IP address from the network'
    # params id, string, required
    # params ipaddr, [String,Array], required
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    
    (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
      nw.ip_lease_dataset.delete_reserved(ip)
    }
    response_to({})
  end

  get '/:id/ports' do
    # description 'List ports on this network'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    ds = nw.network_port_dataset
    
    collection_respond_with(ds) do |paging_ds|
      R::NetworkPortCollection.new(paging_ds).generate
    end
  end

  get '/:id/ports/:port_id' do
    # description "Retrieve details about a port"
    # params id, string, required
    # params port_id, string, required

    # Find a better way to convert to canonical network uuid.
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    port = find_by_uuid(M::NetworkPort, params[:port_id])
    raise E::UnknownNetworkPort, params[:port_id] if port.nil?
    
    # Compare nw.id and port.network_id.

    respond_with(R::NetworkPort.new(port).generate)
  end

  post '/:id/ports' do
    # description "Create new network port"
    # params id, string, required
    nw = find_by_uuid(M::Network, params[:id])

    savedata = {
      :network_id => nw.id
    }
    port = M::NetworkPort.create(savedata)

    respond_with(R::NetworkPort.new(port).generate)
  end

  delete '/:id/ports/:port_id' do
    # description 'Delete a port on this network'
    # params id, string, required
    # params port_id, string, required
    M::NetworkPort.lock!
    nw = find_by_uuid(M::Network, params[:id])

    port = nw.network_port.detect { |itr| itr.canonical_uuid == params[:port_id] }
    raise(UnknownNetworkPort) if port.nil?

    port.destroy
    response_to({})
  end

  put '/:id/ports/:port_id/attach' do
    # description 'Attach a vif to this port'
    # params id, string, required
    # params port_id, string, required
    # params attachment_id, string, required
    result = []

    M::NetworkPort.lock!
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    port = find_by_uuid(M::NetworkPort, params[:port_id])
    raise E::UnknownNetworkPort, params[:port_id] if port.nil?
    raise(E::NetworkPortAlreadyAttached) unless port.instance_nic.nil?

    nic = find_by_uuid(M::InstanceNic, params[:attachment_id])
    raise(E::NetworkPortNicNotFound) if nic.nil?

    # Check that the vif belongs to network?

    instance = nic.instance

    # Find better way of figuring out when an instance is not running.
    if not instance.host_node.nil?
      Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", 'attach_nic',
                             nw.link_interface, nic.canonical_uuid, port.canonical_uuid)
    end

    port.instance_nic = nic
    port.save_changes

    response_to({})
  end

  put '/:id/ports/:port_id/detach' do
    # description 'Detach a vif to this port'
    # params id, string, required
    # params port_id, string, required
    M::NetworkPort.lock!
    nw = find_by_uuid(M::Network, params[:id])
    raise E::UnknownNetwork, params[:id] if nw.nil?
    port = find_by_uuid(M::NetworkPort, params[:port_id])
    raise E::UnknownNetworkPort, params[:port_id] if port.nil?
    # Verify the network id.
    raise(E::NetworkPortNotAttached) if port.instance_nic.nil?

    nic = port.instance_nic
    instance = nic.instance

    # Find better way of figuring out when an instance is not running.
    if not instance.host_node.nil?
      Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", 'detach_nic',
                             nw.link_interface, nic.canonical_uuid, port.canonical_uuid)
    end

    port.instance_nic = nil
    port.save_changes
    response_to({})
  end

  # # Make GRE tunnels, currently used for testing purposes.
  # post '/:id/tunnels' do
  #   # description 'Create a tunnel on this network'
  #   # params id required
  #   # params dest_id required
  #   # params dest_ip required
  #   # params tunnel_id required
  #   nw = find_by_uuid(M::Network, params[:id])

  #   tunnel_name = "gre-#{params[:dest_id]}-#{params[:tunnel_id]}"
  #   command = "/usr/share/axsh/wakame-vdc/ovs/bin/ovs-vsctl add-port br0 #{tunnel_name} -- set interface #{tunnel_name} type=gre options:remote_ip=#{params[:dest_ip]} options:key=#{params[:tunnel_id]}"

  #   system(command)
  #   response_to({})
  # end

  # delete '/:id/tunnels/:tunnel_id' do
  #   # description 'Destroy a tunnel on this network'
  #   # params :id required
  #   # params :tunnel_id required
  #   nw = find_by_uuid(M::Network, params[:id])

  #   tunnel_name = "gre-#{params[:dest_id]}-#{params[:tunnel_id]}"

  #   system("/usr/share/axsh/wakame-vdc/ovs/bin/ovs-vsctl del-port br0 #{tunnel_name}")
  #   response_to({})
  # end

end
