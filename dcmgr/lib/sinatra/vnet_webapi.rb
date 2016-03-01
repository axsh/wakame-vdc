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
        return if not ["POST","DELETE"].include?(request.request_method)

        r = if self.response.header["Content-Type"].include?("application/json")
              ::JSON.parse(self.response.body.first)
            elsif self.response.header["Content-Type"].include?("text/yaml")
              ::YAML.load(self.response.body.first)
            else
              nil
            end
        return if r.nil?

        if request.request_method == "POST"
          r = r.symbolize_keys

          if request.path_info == "/networks"
            VNetAPIClient::Network.create(
              uuid: r[:uuid],
              display_name: r[:uuid],
              ipv4_network: params[:network],
              ipv4_prefix: params[:prefix],
              network_mode: 'virtual'
            )
          end
          
          if request.path_info == "/security_groups"
            VNetAPIClient::SecurityGroup.create(
              uuid: r[:uuid],
              display_name: r[:uuid],
              description: params[:description],
              rules: openvnet_rules(params[:rule]).join("\n")
            )
          end
        else
          VNetAPIClient::Network.delete(r.first) if request.path_info.include?("/networks")
          VNetAPIClient::SecurityGroup.delete(r.first) if request.path_info.include?("/security_groups")
        end
      end
    end
  end

  register VnetWebapi
end
