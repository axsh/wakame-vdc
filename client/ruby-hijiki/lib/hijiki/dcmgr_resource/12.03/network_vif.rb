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
                                 :security_groups,
                                ]

    def attach(network_id)
      Network.find(network_id).attach(self.uuid)
    end

    def detach(network_id)
      Network.find(network_id).detach(self.uuid)
    end

    def add_monitor(params)
      self.post("monitors", params).body
    end

    def delete_monitor(monitor_id)
      self.delete("monitors/#{monitor_id}").body
    end
    
    def update_monitor(monitor_id, params)
      self.put("monitors/#{monitor_id}", params).body
    end

    def list_monitors()
      self.get("monitors")
    end
  end
end
