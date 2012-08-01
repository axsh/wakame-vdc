# -*- coding: utf-8 -*-
require 'weary'

module Hijiki::Request::V1203

  class Instances < Weary::Client
    include Hijiki::Request::Common::Helpers
    namespace 'instances', '12.03'

    get :get, '.{format}' do |resource|
      resource.optional :limit, :service_type, :start
    end

    get :find, '/:id.{format}'

    post :post, '.{format}'
    delete :delete, '/:id.{format}'

    put :start, '/:id/start.{format}'
    put :stop, '/:id/stop.{format}'
    put :reboot, '/:id/reboot.{format}'

    put :put, '/:id.{format}'

    put :backup, '/:id/backup.{format}'
    put :poweroff, '/:id/poweroff.{format}'
    put :poweron, '/:id/poweron.{format}'

  end

end
