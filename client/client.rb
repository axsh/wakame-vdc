require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
require 'active_resource'

URL = 'http://__test__:passwd@localhost:3000'

# Custom Active Resource Class, add request header parameter user_uuid
#
# sample:
# class A < Dcmgr::CertificatedActiveResource
#   self.user_uuid = 'abc'
#   self.site = xxxx
# end

class CertificatedActiveResource < ActiveResource::Base
  self.format = :json
  self.site = URL

  class Connection < ActiveResource::Connection
    attr_accessor :user_uuid
    
    def authorization_header
      @user_uuid ? { 'X-WAKAME_USER' => @user_uuid } : {}
    end
  end
  
  class << self
    attr_accessor :user_uuid
    
    def connection(refresh = false)
      @connection = Connection.new(site, format) if refresh ||
        @connection.nil?
      @connection.user_uuid = user_uuid if user_uuid
      super(false)
      end
  end
end

class Instance < CertificatedActiveResource; end
class FrontendServiceUser < CertificatedActiveResource; end
      
class Account < CertificatedActiveResource; end
class User < CertificatedActiveResource; end
class KeyPair < CertificatedActiveResource; end
      
class NameTag < CertificatedActiveResource; end
class AuthTag < CertificatedActiveResource; end
class TagAttribute < CertificatedActiveResource; end
      
class Instance < CertificatedActiveResource; end
class PhysicalHost < CertificatedActiveResource; end
      
class ImageStorage < CertificatedActiveResource; end
class ImageStorageHost < CertificatedActiveResource; end
      
class LocationGroup < CertificatedActiveResource; end
