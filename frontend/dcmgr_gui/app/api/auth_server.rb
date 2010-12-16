module DcmgrGui
  class AuthServer < Sinatra::Base
    use Rack::MethodOverride

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Wakame dcmgr authorization.")
        throw(:halt, [401, "Not authorized.\n"])
      end
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      (@auth.provided? && @auth.basic? && credentials = @auth.credentials) || ( return FALSE )

      User.authenticate(credentials[0], credentials[1])
    end

    # Neither nginx nor this server removes '..' from the path...
    get '/auth/*' do
      protected!
      command = /\/auth\/(.*)/.match(request.path_info)[1]
      headers 'X-Accel-Redirect' => "/dcmgr_cmd/#{command}"

      "auth response to '#{command}'"
    end
  end
end
