# -*- coding: utf-8 -*-

require 'ipaddress'
require 'dcmgr/endpoints/12.03/responses/ip_pool'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/ip_pools' do

  get do
    # description "List IP pools in account"
    # params start, fixnum, optional
    # params limit, fixnum, optional
    ds = M::IpPool.dataset

    ds = ds.filter(:ip_pools__account_id => params[:account_id]) if params[:account_id]

    ds = datetime_range_params_filter(:networks__created, ds)
    ds = datetime_range_params_filter(:networks__deleted, ds)

    collection_respond_with(ds) do |paging_ds|
      R::IpPoolCollection.new(paging_ds).generate
    end
  end

  get '/:id' do
    # description "Retrieve details about an IP pool"
    # params :id required
    ip_pool = find_by_uuid(M::IpPool, params[:id])
    raise E::UnknownIpPool, params[:id] if ip_pool.nil?

    respond_with(R::IpPool.new(ip_pool).generate)
  end

  put '/:id/acquire' do
    # description ''
    # params id, string, required
    ip_pool = find_by_uuid(M::IpPool, params[:id])
    raise E::UnknownIpPool, params[:id] if ip_pool.nil?

    if params[:network]
      network = M::Network[params[:network]] || raise(E::UnknownNetwork, params[:network])
    end

    network || raise(E::UnknownNetwork, nil)

    st = Dcmgr::Scheduler.service_type(Dcmgr.conf.default_service_type)      
    lease = st.ip_address.schedule({:network => network, :ip_pool => ip_pool})
    
    respond_with({ :id => lease.ip_handle.canonical_uuid,
                   :dc_network_id => lease.network.dc_network.canonical_uuid,
                   :network_id => lease.network.canonical_uuid,
                   :ipv4 => lease.ipv4_s,
                 })
  end

end
    
