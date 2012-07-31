# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/networks' do
  get do
    respond_with(R::NetworkCollection.new(api_request(Hijiki::Request::V1203::Networks.new.get(params))).generate)
  end

  get '/:id' do
    respond_with(R::Network.new(api_request(Hijiki::Request::V1203::Networks.new.find(params))).generate)
  end

  delete '/:id' do
    respond_with(R::Network.new(api_request(Hijiki::Request::V1203::Networks.new.delete(params))).generate)
  end

  post do
    respond_with(R::Network.new(api_request(Hijiki::Request::V1203::Networks.new.put(params))).generate)
  end

  put '/:id/dhcp/reserve' do
    api_request(Hijiki::Request::V1203::Networks.new.dhcp_reserve(params))
    respond_with({})
  end

  put '/:id/dhcp/release' do
    api_request(Hijiki::Request::V1203::Networks.new.dhcp_release(params))
    respond_with({})
  end

  get '/:id/vifs' do
    respond_with(R::NetworkVifCollection.new(api_request(Hijiki::Request::V1203::Networks.new.vifs_get(params))).generate)
  end

  get '/:id/vifs/:vif_id' do
    respond_with(R::NetworkVif.new(api_request(Hijiki::Request::V1203::Networks.new.vifs_find(params))).generate)
  end

  post '/:id/vifs' do
    respond_with(R::NetworkVif.new(api_request(Hijiki::Request::V1203::Networks.new.vifs_post(params))).generate)
  end

  delete '/:id/vifs/:vif_id' do
    respond_with(R::NetworkVif.new(api_request(Hijiki::Request::V1203::Networks.new.vifs_delete(params))).generate)
  end

  put '/:id/vifs/:vif_id/attach' do
    respond_with(R::NetworkVif.new(api_request(Hijiki::Request::V1203::Networks.new.vifs_attach(params))).generate)
  end

  put '/:id/vifs/:vif_id/delete' do
    respond_with(R::NetworkVif.new(api_request(Hijiki::Request::V1203::Networks.new.vifs_detach(params))).generate)
  end

end
