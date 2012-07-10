# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'json'

module Sinatra
  module InternalRequest
    module HelperMethods

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
          b = ::JSON.load(body.shift)
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
