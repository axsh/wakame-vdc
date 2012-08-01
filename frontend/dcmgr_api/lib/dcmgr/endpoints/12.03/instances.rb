# -*- coding: utf-8 -*-

require 'dcmgr/endpoints/12.03/responses/network'

Dcmgr::Endpoints::V1203::CoreAPI.namespace '/instances' do
  get do
    respond_with(R::InstanceCollection.new(api_request(Hijiki::Request::V1203::Instances.new.get(params))).generate)
  end

  get '/:id' do
    respond_with(R::Instance.new(api_request(Hijiki::Request::V1203::Instances.new.find(params))).generate)
  end

  delete '/:id' do
    respond_with(R::Instance.new(api_request(Hijiki::Request::V1203::Instances.new.delete(params))).generate)
  end

  post do
    respond_with(R::Instance.new(api_request(Hijiki::Request::V1203::Instances.new.post(params))).generate)
  end

  put '/:id' do
    respond_with(R::Instance.new(api_request(Hijiki::Request::V1203::Instances.new.put(params))).generate)
  end

  put '/:id/start' do
    api_request(Hijiki::Request::V1203::Instances.new.start(params))
    respond_with({})
  end

  put '/:id/stop' do
    api_request(Hijiki::Request::V1203::Instances.new.stop(params))
    respond_with({})
  end

  put '/:id/reboot' do
    api_request(Hijiki::Request::V1203::Instances.new.reboot(params))
    respond_with({})
  end

  put '/:id/backup' do
    api_request(Hijiki::Request::V1203::Instances.new.backup(params))
    respond_with({})
  end

  put '/:id/poweroff' do
    api_request(Hijiki::Request::V1203::Instances.new.poweroff(params))
    respond_with({})
  end

  put '/:id/poweron' do
    api_request(Hijiki::Request::V1203::Instances.new.poweron(params))
    respond_with({})
  end

end
