require 'sinatra/base'

# Lazy Basic HTTP authentication. Authentication is only forced when the
# credentials are actually needed.
module Sinatra
  module LazyAuth
    class LazyCredentials
      def initialize(app)
        @app = app
        @provided = false
      end

      def user
        credentials!
        @user
      end

      def password
        credentials!
        @password
      end

      def provided?
        @provided
      end

      private
      def credentials!
        unless provided?
          auth = Rack::Auth::Basic::Request.new(@app.request.env)
          unless auth.provided? && auth.basic? && auth.credentials
            @app.authorize!
          end
          @user = auth.credentials[0]
          @password = auth.credentials[1]
          @provided = true
        end
      end

    end

    def authorize!
      r = "#{DRIVER}-deltacloud@#{HOSTNAME}"
      response['WWW-Authenticate'] = %(Basic realm="#{r}")
      throw(:halt, [401, "Not authorized\n"])
    end

    # Request the current user's credentials. Actual credentials are only
    # requested when an attempt is made to get the user name or password
    def credentials
      LazyCredentials.new(self)
    end
  end

  helpers LazyAuth
end
