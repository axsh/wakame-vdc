
module Dcmgr
  module Helpers
    def protected!
      response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth") and \
      throw(:halt, [401, "Not authorized\n"]) and \
      return unless authorized?
    end
    
    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && authorize(@auth.credentials, @auth.credentials)
    end

    def logger
      Dcmgr.logger
    end
    
    def authorize(name, password)
      @user = User.find(:name=>name, :password=>password)
    end

    def authorized_user
      @user
    end
  end
end
