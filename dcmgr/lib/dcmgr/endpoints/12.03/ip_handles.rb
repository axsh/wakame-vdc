# -*- coding: utf-8 -*-

require 'ipaddress'
require 'dcmgr/endpoints/12.03/responses/ip_pool'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/ip_handles' do

  get '/:id' do
    # description "Retrieve details about an IP handle"
    # params :id required
    ip_handle = find_by_uuid(:IpHandle, params[:id]) || raise(UnknownUUIDResource, params[:id])
    raise E::UnknownIpHandle, params[:id] if ip_handle.nil?

    if @account && ip_handle.ip_pool.account_id != @account.canonical_uuid
      raise(E::UnknownUUIDResource, params[:id])
    end

    respond_with(R::IpHandle.new(ip_handle).generate)
  end

  put '/:id/expire_at' do
    # description "Set expires_at date."
    # params :id required
    ip_handle = find_by_uuid(:IpHandle, params[:id]) || raise(UnknownUUIDResource, params[:id])
    raise E::UnknownIpHandle, params[:id] if ip_handle.nil?

    if @account && ip_handle.ip_pool.account_id != @account.canonical_uuid
      raise(E::UnknownUUIDResource, params[:id])
    end

    ip_handle.ip_lease.network_vif.nil? || raise(E::InvalidParameter, :id)

    params[:time_to] || raise(E::InvalidParameter, :time_to)

    time_to = params[:time_to].to_i
    (time_to > 0 && time_to <= 31536000) || raise(E::InvalidParameter, :time_to)

    ip_handle.expires_at = Time.now + time_to
    ip_handle.save_changes

    respond_with(R::IpHandle.new(ip_handle).generate)
  end

end
