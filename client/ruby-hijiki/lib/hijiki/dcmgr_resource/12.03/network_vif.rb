# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class NetworkVif < Base
    include Hijiki::DcmgrResource::Common::ListMethods

    self.prefix = '/api/12.03/networks/:network_id/'
    self.element_name = 'vifs'

    module ClassMethods
      
      def find_vif(network_id, vif_id)
        find(vif_id, :params => { :network_id => network_id })
      end

    end

  end
end
