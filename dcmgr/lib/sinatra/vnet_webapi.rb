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
        return if not ["POST", "PUT", "DELETE"].include?(request.request_method)

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

          vnet_params = {}

          vnet_params[:uuid] = r[:uuid]
          vnet_params[:display_name] = params[:display_name] || r[:uuid]

          if request.path_info == "/networks"
            vnet_params[:ipv4_network] = params[:network]
            vnet_params[:ipv4_prefix] = params[:prefix]
            vnet_params[:segment_uuid] = params[:segment_uuid] if params[:segment_uuid]
            vnet_params[:network_mode] = 'virtual'
            VNetAPIClient::Network.create(vnet_params)
          end

          if request.path_info == "/security_groups"
            vnet_params[:description] = params[:description]
            vnet_params[:rules] = openvnet_rules(params[:rule]).join("\n")
            VNetAPIClient::SecurityGroup.create(vnet_params)
          end
        elsif request.request_method == "PUT"
          _, path, uuid = request.path_info.split("/")

          if path == "security_groups"
            vnet_params = {}

            vnet_params[:display_name] = params[:display_name] if params[:display_name]
            vnet_params[:description] = params[:description] if params[:description]
            vnet_params[:rules] = openvnet_rules(params[:rule]).join("\n") if params[:rule]

            VNetAPIClient::SecurityGroup.update(uuid, vnet_params)
          end

          if path == "networks"
            vnet_params = {}
            vnet_params[:display_name] = params[:display_name] if params[:display_name]
            VNetAPIClient::Network.update(uuid, vnet_params)
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
