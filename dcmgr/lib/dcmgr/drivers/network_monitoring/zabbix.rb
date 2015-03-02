# -*- coding: utf-8 -*-

require 'uri'
require 'net/http'
require 'net/https'
require 'multi_json'
require 'dcmgr/helpers/zabbix_json_rpc'
require 'dcmgr/configurations'

module Dcmgr::Drivers
  class Zabbix < NetworkMonitoring
    include Dcmgr::Logger
    include Dcmgr::Helpers::ZabbixJsonRpc

    class Configuration < NetworkMonitoring::Configuration
      param :api_uri
      param :api_user
      param :api_password
      param :template_id

      def validate(errors)
        unless @config[:api_uri]
          errors << "api_uri is null"
        end
      end
    end

    def configuration
      Dcmgr::Configurations.nwmongw.driver
    end

    def connection
      @connection ||= Connection.new(configuration.api_uri,
                                     configuration.api_user,
                                     configuration.api_password,
                                     logger)
    end

    def rpc_request(method, params)
      logger.debug("JSON-RPC Request: #{method}: #{params}")
      res = connection.request(method, params)
      if logger.debug?
        logger.debug("JSON-RPC Response: #{method}: #{res.json_body}")
      else
        if res.error?
          logger.error("JSON-RPC Response: #{method}: #{res.json_body}")
        end
      end
      raise res.error_message if res.error?

      res
    end

    def register_instance(instance)
    end

    def unregister_instance(instance)
    end

    def update_instance(instance)
    end
  end
end
