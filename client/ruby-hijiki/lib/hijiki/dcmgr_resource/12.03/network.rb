# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203

  module NetworkClassMethods
    def user_attributes
      @@user_attributes ||= [:account_id,
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
                            ]
    end

    def to_user_hash
      result = attributes_to_hash(user_attributes)
      result[:dc_network] = attributes[:dc_network].to_user_hash
      result[:network_services] = attributes[:network_services].collect { |i| i.to_user_hash }
      result
    end
  end

  class Network < Base
    include Hijiki::DcmgrResource::Common::ListMethods

    initialize_user_result nil, NetworkClassMethods
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
