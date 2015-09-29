# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'vnet_api_client'

module Sinatra
  module VnetWebapi
    def enable_vnet_webapi
      endpoint = Dcmgr::Configurations.dcmgr.features.vnet_endpoint
      port = Dcmgr::Configurations.dcmgr.features.vnet_endpoint_port

      VNetAPIClient.uri = "http://#{endpoint}:#{port}"

      after do
        return if not request.request_method == "POST"

        if request.path_info == "/networks"
          VNetAPIClient::Network.create(display_name: "test",
                            ipv4_network: "192.168.100.0",
                            ipv4_prefix: 24)
        end
      end
    end
  end

  register VnetWebapi
end
