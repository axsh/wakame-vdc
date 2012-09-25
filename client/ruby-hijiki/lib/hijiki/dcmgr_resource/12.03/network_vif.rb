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


    def attach(network_id)
      Network.find(network_id).attach(self.uuid)
    end

    def detach(network_id)
      Network.find(network_id).detach(self.uuid)
    end

  end
end
