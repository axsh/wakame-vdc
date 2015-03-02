# encoding: utf-8

require "net/http"
require "net/https"
require "multi_json"

module Dcmgr
  module Helpers
    module ZabbixJsonRpc

      # Net::HTTP based JSON-RPC 2.0 + Zabbix Authentication Utility.
      class Connection
        attr_reader :logger

        def initialize(uri, user, password, logger)
          @uri = uri.is_a?(::URI) ? uri : ::URI.parse(uri)
          @user = user
          @password = password
          @request_id = 0
          @auth_token = nil
          @retry_max = 5
          @logger = logger
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
            return 0 unless error?
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
          tryagain(@retry_max) do
            login if @auth_token.nil?

            http_res = send_request(method, params)
            zabbix_res = RpcResponse.new(http_res)
            if zabbix_res.error? && zabbix_res.error_code == -32602
              @auth_token = nil
              raise "Invalid Authentication Token. Try to fetch new token."
            end
          end
          zabbix_res
        end

        def login
          # force @auth_token to set nil. send_request() will not send the old auth token.
          @auth_token = nil
          http_res = send_request('user.login', {:user=>@user, :password=>@password})

          res = RpcResponse.new(http_res)
          raise "Login failed: #{res.error_message}" if res.error?
          @auth_token = res.result
          res
        end

        def logout
          raise "Connection is unauthorized." if @auth_token.nil?

          http_res = send_request('user.logout', nil)
          @auth_token = nil

          res = RpcResponse.new(http_res)
          raise "Logout failed: #{res.error_message}" if res.error?
          res
        end

        private
        def tryagain(retry_max=3, &blk)
          count=0
          begin
            count += 1
            http_res = blk.call
          rescue => e
            logger.error("#{e.message}: #{e.class}. (retrys #{count}/#{retry_max}")
            if count < retry_max
              sleep 1
              retry
            else
              raise e
            end
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
    end
  end
end
