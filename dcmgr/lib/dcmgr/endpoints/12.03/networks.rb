# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/networks' do
  get do
    # description "List networks in account"
    # params start, fixnum, optional
    # params limit, fixnum, optional
    res = select_index(M::Network, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end

  get '/:id' do
    # description "Retrieve details about a network"
    # params :id required
    nw = find_by_uuid(M::Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    response_to(nw.to_api_document)
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

    response_to(nw.to_api_document)
  end

  delete '/:id' do
    # description "Remove network information"
    # params :id required
    nw = find_by_uuid(M::Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)
    nw.destroy

    response_to([nw.canonical_uuid])
  end

  put '/:id/dhcp/reserve' do
    # description 'Register reserved IP address to the network'
    # params id, string, required
    # params ipaddr, [String,Array], required
    nw = find_by_uuid(M::Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

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
    examine_owner(nw) || raise(E::OperationNotPermitted)
    
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
    examine_owner(nw) || raise(OperationNotPermitted)

    result = []
    nw.network_port.each { |port|
      result << port.to_api_document.merge(:network_id => nw.canonical_uuid)
    }

    response_to(result)
  end

  get '/:id/ports/:port_id' do
    # description "Retrieve details about a port"
    # params id, string, required
    # params port_id, string, required

    # Find a better way to convert to canonical network uuid.
    port = find_by_uuid(M::NetworkPort, params[:port_id])
    nw = find_by_uuid(M::Network, params[:id])
 
    # Compare nw.id and port.network_id.

    response_to(port.to_api_document.merge(:network_id => nw.canonical_uuid))
  end

  post '/:id/ports' do
    # description "Create new network port"
    # params id, string, required
    nw = find_by_uuid(M::Network, params[:id])
    examine_owner(nw) || raise(OperationNotPermitted)

    savedata = {
      :network_id => nw.id
    }
    port = M::NetworkPort.create(savedata)

    response_to(port.to_api_document.merge(:network_id => nw.canonical_uuid))
  end

  delete '/:id/ports/:port_id' do
    # description 'Delete a port on this network'
    # params id, string, required
    # params port_id, string, required
    M::NetworkPort.lock!
    nw = find_by_uuid(M::Network, params[:id])
    examine_owner(nw) || raise(OperationNotPermitted)

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
    port = find_by_uuid(M::NetworkPort, params[:port_id])
    raise(NetworkPortAlreadyAttached) unless port.instance_nic.nil?

    nic = find_by_uuid(M::InstanceNic, params[:attachment_id])
    raise(NetworkPortNicNotFound) if nic.nil?

    nw = find_by_uuid(M::Network, params[:id])
    examine_owner(nw) || raise(OperationNotPermitted)

    # Check that the vif belongs to network?

    instance = nic.instance

    # Find better way of figuring out when an instance is not running.
    if not instance.host_node.nil?
      Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", 'attach_nic',
                             nic.canonical_uuid, port.canonical_uuid)
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
    port = find_by_uuid(M::NetworkPort, params[:port_id])

    # Verify the network id.
    raise(NetworkPortNotAttached) if port.instance_nic.nil?

    nic = port.instance_nic
    instance = nic.instance

    # Find better way of figuring out when an instance is not running.
    if not instance.host_node.nil?
      Dcmgr.messaging.submit("hva-handle.#{instance.host_node.node_id}", 'detach_nic',
                             nic.canonical_uuid, port.canonical_uuid)
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
  #   examine_owner(nw) || raise(OperationNotPermitted)

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
  #   examine_owner(nw) || raise(OperationNotPermitted)

  #   tunnel_name = "gre-#{params[:dest_id]}-#{params[:tunnel_id]}"

  #   system("/usr/share/axsh/wakame-vdc/ovs/bin/ovs-vsctl del-port br0 #{tunnel_name}")
  #   response_to({})
  # end

end
