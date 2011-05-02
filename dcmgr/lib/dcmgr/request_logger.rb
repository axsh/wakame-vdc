# -*- coding: utf-8 -*-

module Dcmgr
  # Rack middleware for loggin each API request
  class RequestLogger
    def initialize(app)
      raise TypeError unless app.is_a?(Dcmgr::Endpoints::CoreAPI)
      @app = app
    end

    def call(env)
      ::Kernel.srand($$ + Time.now.usec + (env['HTTP_X_REAL_IP'] || env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR']).to_i)
      dup._call(env)
    end
    
    def _call(env)
      @log = Models::RequestLog.new
      log_env(env)
      begin
        ret = @app.call(env)
        @log.response_status = ret[0]
        @log.response_msg = ''

        return ret
      rescue ::Exception => e
        @log.response_status = 999
        @log.response_msg = e.message
        raise e
      ensure
        @log.save
      end
    end

    private
    # set common values in Rack env.
    # @params [Hash] env
    def log_env(env)
      #@log.frontend_system_id = env[Dcmgr::Endpoints::RACK_FRONTEND_SYSTEM_ID].to_s
      @log.account_id = env[Dcmgr::Endpoints::HTTP_X_VDC_ACCOUNT_UUID]
      @log.requester_token = env[Dcmgr::Endpoints::HTTP_X_VDC_REQUESTER_TOKEN]
      @log.request_method = env['REQUEST_METHOD']
      @log.api_path = env['PATH_INFO']
      @log.params = ''
    end

  end
end
