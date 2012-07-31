# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/networks' do
  get do
    respond_with(R::Network.new(api_request(Hijiki::Request::V1203::Networks.new.get(params))).generate)
  end

  get '/:id' do
    respond_with(R::Network.new(api_request(Hijiki::Request::V1203::Networks.new.find(params))).generate)
  end
end
