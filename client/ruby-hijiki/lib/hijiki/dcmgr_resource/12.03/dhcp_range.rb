# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class NetworkVif < Base
    include Hijiki::DcmgrResource::Common::ListMethods

    initialize_user_result nil, []

    self.prefix = '/api/12.03/networks/:network_id/'
    self.element_name = 'vifs'

    def attach
      self.put(:attach)
    end

    def detach
      self.put(:detach)
    end

    class << self
      def find_vif(network_id, vif_id)
        find(vif_id, :params => { :network_id => network_id })
      end

      def detach_vif(network_id, vif_id)
        find_vif(network_id, vif_id).detach
      end
    end

  end
end
