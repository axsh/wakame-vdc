# -*- coding: utf-8 -*-

Dcmgr::Endpoints::V1112::CoreAPI.namespace '/networks' do
  def network_generate(nw)
    h = nw.to_api_document
    h.merge!({ :id => nw.canonical_uuid,
               :dc_network => nw.dc_network ? nw.dc_network.to_hash : nil,
               :nat_network_id => nw.nat_network ? nw.nat_network.canonical_uuid : nil,
             })
    [:dc_network_id, :gateway_network_id].each { |k| h.delete(k) }

    h
  end

  def network_vif_generate(vif)
    h = vif.to_api_document
    h.delete(instance_id)
    h.merge!({:network_id => network_id},
             :security_groups => vif.security_groups.map {|n| n.canonical_uuid })
    h
  end

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

    response_to(network_generate(nw))
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
      :network_mode => params[:network_mode]
    }
    nw = M::Network.create(savedata)

    response_to(network_generate(nw))
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

    nw.label_tag(:NetworkGroup, params[:name], @account.canonical_uuid)
    response_to({})
  end

  put '/:id/del_pool' do
    # description 'Unlabel network pool name'
    # param :name required
    M::Tag.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    nw.unlabel_tag(:NetworkGroup, params[:name], @account.canonical_uuid)
    response_to({})
  end

  get '/:id/get_pool' do
    # description 'List network pool name'
    # param :name required
    M::Tag.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    res = nw.tags_dataset.filter(:type_id=>Tags.type_id(:NetworkGroup)).all.map{|i| i.to_api_document }
    response_to(res)
  end

  # Temporary names as the current code is incapable of having
  # multiple names with different operations.
  get '/:id/get_vif' do
    # description 'List vifs on this network'
    # params start, fixnum, optional
    # params limit, fixnum, optional
    M::NetworkVif.lock!
    nw = find_by_uuid(:Network, params[:id])
    examine_owner(nw) || raise(E::OperationNotPermitted)

    result = []
    nw.network_vif.each { |vif|
      result << network_vif_generate(vif)
    }

    response_to(result)
  end

end
