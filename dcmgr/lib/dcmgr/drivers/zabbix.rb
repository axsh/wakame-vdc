# -*- coding: utf-8 -*-

require 'uri'
require 'net/http'
require 'net/https'
require 'multi_json'

module Dcmgr::Drivers
  class Zabbix < NetworkMonitoring
    include Dcmgr::Logger
    include Fuguta::Configuration::ConfigurationMethods

    def_configuration do
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

    # Net::HTTP based JSON-RPC 2.0 + Zabbix Authentication Utility.
    class Connection

      def initialize(uri, user, password)
        @uri = uri.is_a?(::URI) ? uri : ::URI.parse(uri)
        @user = user
        @password = password
        @request_id = 0
        @auth_token = nil
      end

      class RpcResponse
        def initialize(http_res)
          raise ArgumentError, "http_res must be a 'Net::HTTPResponse'. Got '#{http_res.class}'" unless http_res.is_a?(Net::HTTPResponse)
          @res = http_res
          @json = nil
        end

        def code
          @res.code.to_i
        end

        def error?
          self.code != 200 || (json_body.is_a?(Hash) && json_body['error'])
        end

        def error_code
          return unless error?
          (self.code != 200 ? code : json_body['error']['code'].to_i) rescue 0
        end

        def error_message
          return unless error?
          begin
            if self.code != 200
              "Could not get a 200 response from the Zabbix API.  Further details are unavailable."
            else
              stripped_message = (json_body['error']['message'] || '').gsub(/\.$/, '')
              stripped_data = (json_body['error']['data'] || '').gsub(/^\[.*?\] /, '')
              [stripped_message, stripped_data].map(&:strip).reject(&:empty?).join(', ')
            end
          rescue => e
            "No details available."
          end
        end

        def json_body
          @json ||= parse
        end

        def result
          raise "#{error_message}" if error?
          json_body['result']
        end

        def first
          result.first
        end

        private
        def parse
          return if self.code != 200

          begin
            return MultiJson.load(@res.body)
          rescue MultiJson::DecodeError => e
            STDERR.puts e
          end
        end
      end

      def request(method, params)
        login if @auth_token.nil?

        http_res = send_request(method, params)

        RpcResponse.new(http_res)
      end

      def login
        # force @auth_token to set nil. send_request() will not send the old auth token.
        @auth_token = nil
        http_res = tryagain do
          send_request('user.login', {:user=>@user, :password=>@password})
        end

        res = RpcResponse.new(http_res)
        raise "Login failed: #{res.error_message}" if res.error?
        @auth_token = res.result
        res
      end

      def logout
        raise "Connection is unauthorized." if @auth_token.nil?

        http_res = tryagain do
          send_request('user.logout', nil)
        end

        res = RpcResponse.new(http_res)
        raise "Logout failed: #{res.error_message}" if res.error?
        res
      end

      private
      def tryagain(&blk)
        count=0
        begin
          http_res = blk.call

          #if http_res.code.to_i > 500
        end
      end

      def send_request(method, params)
        @http ||= begin
                    http = Net::HTTP.new(@uri.host, @uri.port)
                    if @uri.scheme == 'https'
                      http.use_ssl = true
                    end
                    http
                  end

        @request_id += 1

        rpc_message = {
          :jsonrpc=>'2.0',
          :id => @request_id,
          :method => method,
        }
        rpc_message[:params]=params if params
        rpc_message[:auth]=@auth_token if @auth_token

        @http.request(Net::HTTP::Post.new(@uri.path).tap do |req|
                        req['Content-Type'] = 'application/json-rpc'
                        req.body = MultiJson.dump(rpc_message)
                      end)
      end
    end

    def initialize()
    end

    def configuration
      Dcmgr.conf.driver || raise("driver(:Zabbix) section is undefined")
    end

    def connection
      @connection ||= Connection.new(configuration.api_uri,
                                     configuration.api_user,
                                     configuration.api_password)
    end

    def rpc_request(method, params)
      logger.debug("JSON-RPC Request: #{method}: #{params}")
      res = connection.request(method, params)
      logger.debug("JSON-RPC Response: #{method}: #{res.json_body}")
      raise res.error_message if res.error?

      res
    end

    def register_instance(instance)
    end


    def unregister_instance(instance)
    end

  end
end
