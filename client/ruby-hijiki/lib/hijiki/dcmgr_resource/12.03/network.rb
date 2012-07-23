# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203

  class Network < Base
    include Hijiki::DcmgrResource::Common::ListMethods

    initialize_user_result nil, [:account_id,
                                 :uuid,
                                 :ipv4_network,
                                 :ipv4_gw,
                                 :prefix,
                                 :metric,
                                 :domain_name,
                                 :dns_server,
                                 :dhcp_server,
                                 :metadata_server,
                                 :metadata_server_port,
                                 # :nat_network_id,
                                 # :dc_network_id,
                                 :description,
                                 :created_at,
                                 :updated_at,
                                 # :gateway_network_id,
                                 :network_mode,
                                 :bandwidth,
                                 :service_type,
                                 :display_name,
                                 # :bandwidth_mark,
                                ], [:dc_network], [:network_services]
    initialize_user_result 'DcNetwork', [:uuid,
                                         :name,
                                         :description,
                                         :offering_network_modes,
                                         :created_at,
                                         :updated_at,
                                        ]
    initialize_user_result 'NetworkService', [:name,
                                              :description,
                                              :created_at,
                                              :updated_at,
                                             ]

    def find_vif(vif_id)
      NetworkVif.find(vif_id, :params => { :network_id => self.id })
    end
  end

end
