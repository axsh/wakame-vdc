# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'vnet_api_client'
require 'json'
require 'yaml'

module Sinatra
  module VnetWebapi
    def enable_vnet_webapi
      endpoint = Dcmgr::Configurations.dcmgr.features.vnet_endpoint
      port = Dcmgr::Configurations.dcmgr.features.vnet_endpoint_port

      VNetAPIClient.uri = "http://#{endpoint}:#{port}"

      after do
        return if not request.request_method == "POST"

        r = if self.response.header["Content-Type"].include?("application/json")
              ::JSON.parse(self.response.body.first).symbolize_keys
            elsif self.response.header["Content-Type"].include?("text/yaml")
              ::YAML.load(self.response.body.first).symbolize_keys
            else
              nil
            end

        return if r.nil?

        if request.path_info == "/networks"
          VNetAPIClient::Network.create(
            uuid: r[:uuid],
            display_name: r[:uuid],
            ipv4_network: params[:network],
            ipv4_prefix: params[:prefix],
            network_mode: 'virtual'
          )
        end
      end
    end
  end

  register VnetWebapi
end
