module Dcmgr::FsuserAuthorizer
  extend self

  class UnkownAuthType < StandardError; end

  def auth_type=(type)
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
