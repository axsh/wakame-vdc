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

  post do
    # description "Create IP pool"
    # params :display_name, string, required
    # params :dc_networks, array, required

    raise E::InvalidParameter, :display_name if params[:display_name].class != String
    raise E::InvalidParameter, params[:dc_networks] if params[:dc_networks].class != Array

    fields = {
      :account_id => @account.canonical_uuid,
      :display_name => params[:display_name],
    }

    ip_pool = M::IpPool.create(fields)

    params[:dc_networks].each { |dcn|
      if M::DcNetwork.check_uuid_format(dcn)
        dc_network = find_by_uuid(M::DcNetwork, dcn)
      else
        dc_network = M::DcNetwork.find(:name => dcn)
      end

      next unless dc_network

      M::IpPoolDcNetwork.create({:ip_pool_id => ip_pool.id, :dc_network_id => dc_network.id})
    }

    respond_with(R::IpPool.new(ip_pool).generate)
  end  

  delete '/:id' do
    # description "Remove IP pool information"
    # params :id required
    ip_pool = find_by_uuid(M::IpPool, params[:id])
    raise E::UnknownIpPool, params[:id] if ip_pool.nil?
    ip_pool.destroy

    respond_with([ip_pool.canonical_uuid])
  end

  get '/:id' do
    # description "Retrieve details about an IP pool"
    # params :id required
    ip_pool = find_by_uuid(M::IpPool, params[:id])
    raise E::UnknownIpPool, params[:id] if ip_pool.nil?

    respond_with(R::IpPool.new(ip_pool).generate)
  end

  get '/:id/ip_handles' do
    # description "Retrieve ip handles belonging to an IP pool"
    # params :id required
    ip_pool = find_by_uuid(M::IpPool, params[:id])
    raise E::UnknownIpPool, params[:id] if ip_pool.nil?

    ds = ip_pool.ip_handles_dataset
    
    collection_respond_with(ds) do |paging_ds|
      R::IpHandleCollection.new(paging_ds).generate
    end
  end

  put '/:id/acquire' do
    # description ''
    # params id, string, required
    ip_pool = find_by_uuid(M::IpPool, params[:id])
    raise E::UnknownIpPool, params[:id] if ip_pool.nil?

    if params[:network_id]
      network = M::Network[params[:network_id]] || raise(E::UnknownNetwork, params[:network_id])
    end

    raise(E::UnknownNetwork, nil) unless network
    raise(E::NetworkNotInDcNetwork, nil) unless ip_pool.has_dc_network(network.dc_network)

    st = Dcmgr::Scheduler.service_type(Dcmgr.conf.default_service_type)      
    lease = st.ip_address.schedule({:network => network, :ip_pool => ip_pool})
    
    respond_with({ :ip_handle_id => lease.ip_handle.canonical_uuid,
                   :dc_network_id => lease.network.dc_network.canonical_uuid,
                   :network_id => lease.network.canonical_uuid,
                   :ipv4 => lease.ipv4_s,
                 })
  end

  put '/:id/release' do
    # description ''
    # params id, string, required
    ip_pool = find_by_uuid(M::IpPool, params[:id])
    raise E::UnknownIpPool, params[:id] if ip_pool.nil?
    ip_handle = ip_pool.ip_handles_dataset.alives.where(:uuid => M::IpHandle.trim_uuid(params[:ip_handle_id])).first

    raise E::UnknownIpHandle, params[:ip_handle_id] if ip_handle.nil?
    raise E::InvalidParameter, params[:ip_handle_id] if ip_handle.ip_pool != ip_pool
    raise E::IpHandleInUse, params[:ip_handle_id] unless ip_handle.can_destroy

    ip_handle.destroy

    respond_with({})
  end

end
    
