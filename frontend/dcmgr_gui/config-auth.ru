# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

require 'rack/request'
require 'rack/response'

module DcmgrGui
  class AuthServer
    def call(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      command = /\/auth\/(.*)/.match(req.path_info)[1]
      res.headers['X-Accel-Redirect'] = "/dcmgr_cmd/" + command
      res.finish
    end
  end
end

run DcmgrGui::AuthServer.new