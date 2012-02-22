# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/networks' do
  # description "Networks for account"
  get do
    # description "List networks in account"
    # params start, fixnum, optional
    # params limit, fixnum, optional
    res = select_index(:Network, {:start => params[:start],
                         :limit => params[:limit]})
    response_to(res)
  end

  get '/:id' do
    # description "Retrieve details about a network"
    # params :id required
    nw = find_by_uuid(:Network, params[:id])
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
    M::Network.lock!
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
    M::Network.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)
    nw.destroy

    response_to([nw.canonical_uuid])
  end

  put '/:id/reserve' do
    # description 'Register reserved IP address to the network'
    # params id, string, required
    # params ipaddr, [String,Array], required
    M::IpLease.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
      nw.ip_lease_dataset.add_reserved(ip)
    }
    response_to({})
  end

  put '/:id/release' do
    # description 'Unregister reserved IP address from the network'
    # params id, string, required
    # params ipaddr, [String,Array], required
    M::IpLease.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
      nw.ip_lease_dataset.delete_reserved(ip)
    }
    response_to({})
  end

  put '/:id/add_pool' do
    # description 'Label network pool name'
    # param :name required
    M::Tag.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    nw.label_tag(:NetworkPool, params[:name], @account.canonical_uuid)
    response_to({})
  end

  put '/:id/del_pool' do
    description 'Unlabel network pool name'
    # param :name required
    control do
      M::Tag.lock!
      nw = find_by_uuid(:Network, params[:id])
      examine_owner(nw) || raise(E::OperationNotPermitted)

      nw.unlabel_tag(:NetworkPool, params[:name], @account.canonical_uuid)
      response_to({})
    end
  end

  put '/:id/get_pool' do
    description 'List network pool name'
    # param :name required
    control do
      M::Tag.lock!
      nw = find_by_uuid(:Network, params[:id])
      examine_owner(nw) || raise(E::OperationNotPermitted)

      res = nw.tags_dataset.filter(:type_id=>Tags.type_id(:NetworkPool)).all.map{|i| i.to_api_document }
      response_to(res)
    end
  end

  # Temporary names as the current code is incapable of having
  # multiple names with different operations.
  get '/:id/get_port' do
    # description 'List ports on this network'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    M::NetworkPort.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    result = []
    nw.network_port.each { |port|
      result << port.to_api_document.merge(:network_id => nw.canonical_uuid)
    }

    response_to(result)
  end

  put '/:id/add_port' do
    # description 'Create a port on this network'
    M::NetworkPort.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    savedata = {
      :network_id => nw.id
    }
    port = M::NetworkPort.create(savedata)

    response_to(port.to_api_document.merge(:network_id => nw.canonical_uuid))
  end

  put '/:id/del_port' do
    # description 'Create a port on this network'
    # param :port_id required
    M::NetworkPort.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    port = nw.network_port.detect { |itr| itr.canonical_uuid == params[:port_id] }
    raise(E::UnknownNetworkPort) if port.nil?

    port.destroy
    response_to({})
  end

end

# Should be under '/networks/{network-id}/ports', however due to
# lack of namespaces we put the create and index calls in the
# root namespace.
Dcmgr::Endpoints::V1112::CoreAPI.namespace '/ports' do
  # description "Ports on a network"

  get '/:id' do
    # description "Retrieve details about a port"
    # params :id required
    port = find_by_uuid(:NetworkPort, params[:id])

    # Find a better way to convert to canonical network uuid.
    nw = find_by_uuid(:Network, port[:network_id])

    response_to(port.to_api_document.merge(:network_id => nw.canonical_uuid))
  end
  
  # delete '/:id' do
  #   # description "Remove a port"
  #   # params :id required
  #     response_to({})
  # end

  put '/:id/attach' do
    # description 'Attach a vif to this port'
    # params :id required
    # params :attachment_id required
    result = []

    M::NetworkPort.lock!
    port = find_by_uuid(:NetworkPort, params[:id])
    raise(E::NetworkPortAlreadyAttached) unless port.instance_nic.nil?

    nic = find_by_uuid(:InstanceNic, params[:attachment_id])
    raise(E::NetworkPortNicNotFound) if nic.nil?

    nw = find_by_uuid(:Network, port[:network_id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    # Verify that the vif belongs to network?

    port.instance_nic = nic
    port.save_changes
    response_to({})
  end

  put '/:id/detach' do
    # description 'Detach a vif from this port'
    # param :port_id required
    # M::NetworkPort.lock!
    # nw = find_by_uuid(:Network, params[:id])
    # examine_owner(nw) || raise(E::OperationNotPermitted)

    # port = nw.network_port.detect { |itr| itr.canonical_uuid == params[:port_id] }
    # raise(E::UnknownNetworkPort) if port.nil?

    # port.destroy
    response_to({})
  end
end
