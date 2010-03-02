
module Dcmgr
  module Helpers
    def logger
      Dcmgr.logger
    end

    def json_request(request)
      ret = Hash.new
      
      request.GET.each{|k,v|
        ret[:"_get_#{k}"] = v
      }
      
      if request.content_length.to_i > 0
        body = request.body.read
        parsed = JSON.parse(body)
        Dcmgr.logger.debug("request: " + parsed.inspect)
        
        parsed.each{|k,v|
          ret[k.to_sym] = v
        }
      end
      Dcmgr.logger.debug("request: " + ret.inspect)
      ret        
    end
  end

  module AuthorizeHelpers
    def protected!
      response['WWW-Authenticate'] = %(Basic realm="HTTP Auth") and
        throw(:halt, [401, "Not authorized\n"]) and
        return unless authorized?
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? &&
        authorize(@auth.credentials, @auth.credentials)
    end

    def authorize(name, password)
      @user = User.find(:name=>name, :password=>password)
      @user
    end

    def authorized_user
      @user
    end
  end
  
  module NoAuthorizeHelpers
    def protected!
      true
    end
    
    def authorized?
      true
    end
    
    def authorize(name, password)
      true
    end

    def authorized_user
      nil
    end
  end
end
