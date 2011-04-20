# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

require 'rack/request'
require 'rack/response'
require 'oauth/request_proxy/rack_request'

module DcmgrGui
  class AuthServer
    def call(env)
      
      req = Rack::Request.new(env)
      res = Rack::Response.new
      
      #Request env store to tmporary values for oauth sign.
      tmp_req = {:host => req.env['HTTP_HOST'],
                 :port => req.env['SERVER_PORT'],
                 :path_info => req.env['PATH_INFO'],
                 :url_scheme => req.env['rack.url_scheme']
                }

      if oauth_consumer_request(req)
        
        #Revert to original env.
        req.env['HTTP_HOST'] = tmp_req[:host]
        req.env['SERVER_PORT'] = tmp_req[:port]
        req.env['PATH_INFO'] = tmp_req[:path_info]
        req.env['rack.url_scheme'] = tmp_req[:url_scheme]
        
        command = self.get_command(req.path_info)
        res.headers['X-Accel-Redirect'] = "/dcmgr_cmd/" + command

      else
         res.status = 403
         res.headers['Content-Type'] = "text/html"
         res.body = "Access denied."
      end
      res.finish
    end
    
    def oauth_consumer_request(request)
      
      command = self.get_command(request.path_info)
      request.env['HTTP_HOST'] = Rails::configuration.proxy_host
      request.env['SERVER_PORT'] = Rails::configuration.proxy_port.to_s
      request.env['PATH_INFO'] = '/api/' + command
      request.env['rack.url_scheme'] = Rails::configuration.proxy_scheme

      begin
        begin
          signature = OAuth::Signature.build(request) do |request_proxy|
            @oauth_consumer = OauthConsumer.find(:key => request_proxy.consumer_key)
            if @oauth_consumer.nil?
              return false
            end
            [nil, @oauth_consumer.secret]
          end
      
          valid = signature.verify
      
          if valid
            return true
          else
            return false
          end
        rescue OAuth::Error => e
          return false
        end
      end
    end
   
    def get_command(path_info)
        command = /\/auth\/(.*)/.match(path_info)[1]
    end    
  end
end

run DcmgrGui::AuthServer.new
