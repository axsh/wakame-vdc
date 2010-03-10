require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
require 'active_resource'

class CertificatedActiveResource < ActiveResource::Base
  class Connection < ActiveResource::Connection
    attr_accessor :user_uuid
    
    def authorization_header
      @user_uuid ? { 'X-WAKAME_USER' => @user_uuid } : {}
    end
  end
  
  class << self
    def user_uuid
      read_inheritable_attribute(:user_uuid)
    end

    def user_uuid=(uuid)
      write_inheritable_attribute(:user_uuid, uuid)
    end
      
    def connection(refresh = false)
      @connection = Connection.new(site, format) if refresh ||
        @connection.nil?
      @connection.user_uuid = user_uuid if user_uuid
      super(false)
      end
  end

  self.format = :json
end
