# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/networks' do
  get do
    respond_with({:foo => 'bar'})
  end
end
