# -*- coding: utf-8 -*-
require 'weary'

module Hijiki::Request::V1203

  class Networks < Weary::Client
    include Hijiki::Request::Common::Helpers
    namespace 'networks', '12.03'

    get :get, '.{format}' do |resource|
      resource.optional :limit, :service_type, :start
    end

    get :find, '/:id.{format}'

    delete :delete, '/:id.{format}'
    post :post, '.{format}'

    put :dhcp_reserve, '/:id/dhcp/reserve.{format}'
    put :dhcp_release, '/:id/dhcp/release.{format}'

    get :vifs_get, '/:id/vifs.{format}'
    get :vifs_find, '/:id/vifs/:vif_id.{format}'

    post :vifs_post, '/:id/vifs.{format}'
    delete :vifs_delete, '/:id/vifs/:vif_id.{format}'

    put :vifs_attach, '/:id/vifs/:vif_id/attach.{format}'
    put :vifs_detach, '/:id/vifs/:vif_id/detach.{format}'

  end

end
