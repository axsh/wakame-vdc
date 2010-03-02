module Dcmgr::FsuserAuthorizer
  extend self

  class UnknownAuthType < StandardError; end
  class NotAuthorized < StandardError; end

  def auth_type=(type)
    check_auth_type(type)
    @auth_type = type
    @users = {}
  end

  def check_auth_type(type)
    raise UnknownAuthType, "unkown #{type}" unless [:ip, :basic].include? type
  end

  def auth_type
    @auth_type
  end

  def auth_users=(users)
    # :ip type
    # {username=>ip, ...}

    # :basic format
    # {username=>password, ...}

    check_auth_type(@auth_type)
    @users = users
  end

  def find_by_ip(req_ip)
    match = @users.detect{|username, ip|
      ip == req_ip
    }
    match ? match[0] : nil
  end

  def find_by_basic(req_username, req_password)
    match = @users.detect{|username, password|
      username == req_username && password == req_password
    }
    match ? match[0] : nil
  end

  def authorize(request)
    check_auth_type(@auth_type)

    user = case auth_type
           when :ip
             ip = request.env["REMOTE_ADDR"]
             find_by_ip(ip)
             
           when :basic
              bauth= Rack::Auth::Basic::Request.new(request.env)
             bauth.provided? && bauth.basic? &&
               find_by_basic(*bauth.credentials)
           end
    raise NotAuthorized, "not authorized" unless user
    user
  end
end
