# -*- coding: utf-8 -*-

require 'rack/request'

module Dcmgr::Rack
  # Rack middleware for logging Dcmgr API request.
  class RequestLogger
    HTTP_X_VDC_REQUEST_ID='HTTP_X_VDC_REQUEST_ID'.freeze
    HEADER_X_VDC_REQUEST_ID='X-VDC-Request-ID'.freeze
    RACK_REQUEST_LOG_KEY='vdc.request_log'.freeze
      
    include Dcmgr::Logger

    def initialize(app, with_header=true)
      @app = app
      @with_header = with_header
    end

    def call(env)
      dup._call(env)
    end
    
    def _call(env)
      request = ::Rack::Request.new(env)
      env[RACK_REQUEST_LOG_KEY] = @log = Dcmgr::Models::RequestLog.new
      log_env(request)
      begin
        ret = @app.call(env)
        @log.response_status = ret[0]
        @log.response_msg = ''

        # inject X-VDC-Request-ID header
        if @with_header
          ret[1] = (ret[1] || {}).merge({HEADER_X_VDC_REQUEST_ID=>@log.request_id})
        end
        return ret
      rescue ::Exception => e
        @log.response_status = 999
        @log.response_msg = e.message
        raise e
      ensure
        @log.class.db.transaction do
          @log.save
          logger.info("Request received [request_id: #{@log.request_id] [account_id: #{@log.account_id}] [login_id: #{@log.requester_token}]")
        end
      end
    end

    private
    # set common values in Rack env.
    # @params [Rack::Request] request
    def log_env(request)
      env = request.env
      #@log.frontend_system_id = env[Dcmgr::Endpoints::RACK_FRONTEND_SYSTEM_ID].to_s
      if env[Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID].nil? || env[Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID] == ''
        @log.account_id = 'nil'
      else
        @log.account_id = env[Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID]
      end
      @log.requester_token = env[Dcmgr::Endpoints::HTTP_X_VDC_REQUESTER_TOKEN]
      @log.request_method = env['REQUEST_METHOD']
      @log.api_path = env['PATH_INFO']
      @log.params = request.params
    end

  end
end
