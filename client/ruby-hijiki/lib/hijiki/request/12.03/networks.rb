# -*- coding: utf-8 -*-
require 'weary'

module Hijiki::Request::V1203

  class Networks < Weary::Client
    include Hijiki::Request::Common::Helpers
    namespace 'networks', '12.03'

    get :get, ''
    get :find, '/:id'

    delete :delete, '/:id'
    put :put, '/:id'

    put :dhcp_reserve, '/:id/dhcp/reserve'
    put :dhcp_release, '/:id/dhcp/release'

    get :vifs_get, '/:id/vifs'
    get :vifs_find, '/:id/vifs/:vif_id'

    post :vifs_post, '/:id/vifs'
    delete :vifs_delete, '/:id/vifs/:vif_id'

    put :vifs_attach, '/:id/vifs/:vif_id/attach'
    put :vifs_detach, '/:id/vifs/:vif_id/detach'
    
  end

end
