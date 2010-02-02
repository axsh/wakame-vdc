
module Dcmgr
  module Helpers
    def logger
      Dcmgr.logger
    end
  end

  module AuthorizeHelpers
    def protected!
      response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth") and \
      throw(:halt, [401, "Not authorized\n"]) and \
      return unless authorized?
    end
    
    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && authorize(@auth.credentials, @auth.credentials)
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
