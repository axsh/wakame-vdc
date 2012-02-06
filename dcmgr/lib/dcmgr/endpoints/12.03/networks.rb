# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/networks' do
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
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)
    nw.destroy

    response_to([nw.canonical_uuid])
  end

  put '/:id/dhcp/reserve' do
    # description 'Register reserved IP address to the network'
    # params id, string, required
    # params ipaddr, [String,Array], required
    nw = find_by_uuid(:Network, params[:id])
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
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)
    
    (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
      nw.ip_lease_dataset.delete_reserved(ip)
    }
    response_to({})
  end
end
