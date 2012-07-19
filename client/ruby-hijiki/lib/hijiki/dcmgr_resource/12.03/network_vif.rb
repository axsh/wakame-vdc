# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class NetworkVif < Base
    include Hijiki::DcmgrResource::Common::ListMethods

    initialize_user_result nil, [:uuid,
                                 :instance_id,
                                 :network_id,
                                 :nat_network_id,
                                 :mac_addr,
                                 :device_index,
                                 :deleted_at,
                                 :created_at,
                                 :updated_at,
                                 :account_id,
                                 :address,
                                 :nat_ip_lease,
                                 :instance_uuid,
                                 :host_node_id,
                                 :security_groups,
                                ]

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
