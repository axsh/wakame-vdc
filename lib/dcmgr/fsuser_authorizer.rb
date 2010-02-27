module Dcmgr::FsuserAuthorizer
  extend self

  class UnknownAuthType < StandardError; end

  def auth_type=(type)
    raise UnknownAuthType, "unkown #{type}" unless [:ip, :basic].include? type
    @auth_type = type
  end

  def auth_type
    @auth_type
  end

  def auth_users=(users)
    @auth_users = users
  end

  def auth_users
    @auth_users
  end
end
