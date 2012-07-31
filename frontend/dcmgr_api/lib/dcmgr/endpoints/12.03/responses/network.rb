# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class Network < Dcmgr::Endpoints::ResponseGenerator
    def initialize(network)
      raise ArgumentError if !network.is_a?(Hash)
      @network = network
    end

    def generate()
      result = filter_response(@network, [:account_id,
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
                                          # :bandwidth_mark
                                         ])
      result[:dc_network] = filter_response(@network[:dc_network.to_s],
                                            [:uuid,
                                             :name,
                                             :description,
                                             :offering_network_modes,
                                             :created_at,
                                             :updated_at,
                                            ])
      result[:network_services] = @network[:network_services.to_s].collect { |value|
        filter_response(value, [:name,
                                :description,
                                :created_at,
                                :updated_at,
                               ])
      }
      result
    end
  end

  class NetworkCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(array)
      raise ArgumentError if !array.is_a?(Array)
      @array = array
    end

    def generate()
      filter_collection(@array, Network)
    end
  end

  class NetworkVif < Dcmgr::Endpoints::ResponseGenerator
    def initialize(network)
      raise ArgumentError if !network.is_a?(Hash)
      @network = network
    end

    def generate()
      result = filter_response(@network, [:uuid,
                                          :network_id,
                                          :nat_network_id,
                                          :instance_uuid,
                                          :mac_addr,
                                          :device_index,
                                          :deleted_at,
                                          :created_at,
                                          :updated_at,
                                          :account_id,
                                          :address,
                                          :nat_ip_lease,
                                          :host_node_id,
                                          # :security_groups,
                                         ])
      result[:network] = NetworkVif.new(@network[:network.to_s]).generate
      result
    end
  end

  class NetworkVifCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(array)
      raise ArgumentError if !array.is_a?(Array)
      @array = array
    end

    def generate()
      filter_collection(@array, NetworkVif)
    end
  end

end
