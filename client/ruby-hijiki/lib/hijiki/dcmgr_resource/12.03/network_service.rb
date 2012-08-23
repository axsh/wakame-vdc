# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class NetworkService < Base
    include Hijiki::DcmgrResource::Common::ListMethods

    initialize_user_result nil, [:network_id,
                                 :created_at,
                                 :updated_at,
                                 :address,
                                ]

    self.prefix = '/api/12.03/networks/:network_id/'
    self.element_name = 'services'

    class << self
      def find_service(network_id, service_name)
        find(service_name, :params => { :network_id => network_id })
      end
    end

  end
end
