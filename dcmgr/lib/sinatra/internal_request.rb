# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'json'
require 'rack/test'

module Sinatra
  module InternalRequest

    module HelperMethods
      # request_forward.get('/')
      # request_forward.post('/instances', {:xxxx=>1})
      # request_forward.post('/instances', {}, {:input=>'{"cpu_cores":2}', 'CONTENT_TYPE'=>'application/json'})
      #
      # # send DELETE with additional heder and get the response.
      # request_forward do
      #   header('X-VDC-Account-UUID', 'a-xxxxxxx')
      #   delete('/instances/i-xxxxxx')
      # end.last_response
      def request_forward(&blk)
        mock = Rack::Test::Session.new(Rack::MockSession.new(self.dup))
        mock.instance_eval {
          def block_eval(&blk)
            blk.arity == 1 ? blk.call(self) : instance_exec(&blk)
          end
        }
        mock.block_eval(&blk) if blk
        mock
      end

      def internal_request(url, request_params, options={})

        _req = ::Rack::Request.new \
          ::Rack::MockRequest.env_for(url,
          :params => request_params)

        _req.env['SERVER_NAME'] = env['SERVER_NAME']
        _req.env['SERVER_PORT'] = env['SERVER_PORT']
        _req.env['CONTENT_TYPE'] = 'application/json'
        _req.env['REQUEST_METHOD'] = env['REQUEST_METHOD']
        _req.env['HTTP_X_VDC_ACCOUNT_UUID'] = env['HTTP_X_VDC_ACCOUNT_UUID']
        _req.env.merge!(options)

        begin
          http_status, headers, body = self.dup.call(_req.env)
        rescue ::Exception => e
          logger.error(e)
        end

        if http_status == 200
          buf = ""
          body.each {|b|
            buf << b
          }
          b = ::JSON.load(buf)
        else
          b = body
        end

        [http_status, headers, b]
      end

    end

    def self.registered(app)
      app.helpers HelperMethods
    end
  end
end
