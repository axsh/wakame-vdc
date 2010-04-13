
require 'active_resource'

# Custom Active Resource Class, add request header parameter user_uuid
#
# sample:
# class A < Dcmgr::CertificatedActiveResource
#   self.user_uuid = 'abc'
#   self.site = xxxx
# end
module Dcmgr
  module Client

    class Base < ActiveResource::Base
      class Connection < ActiveResource::Connection
        attr_accessor :user_uuid
        
        def authorization_header
          @user_uuid ? { 'X-WAKAME_USER' => @user_uuid } : {}
        end
      end
      
      class << self
        def user_uuid
          if defined?(@user_uuid)
            @user_uuid
          elsif superclass != Object && superclass.respond_to?(:user_uuid)
            superclass.user_uuid
          end
        end

        attr_writer :user_uuid
        
        def connection(refresh = false)
          @connection = Connection.new(site, format) if refresh ||
            @connection.nil?
          @connection.user_uuid = user_uuid if user_uuid
          super(false)
        end
      end

      self.format = :json
    end

    class Instance < Base; end
    class FrontendServiceUser < Base; end
    
    class Account < Base; end
    class User < Base; end
    class KeyPair < Base; end
    
    class NameTag < Base; end
    class AuthTag < Base; end
    class TagAttribute < Base; end
    
    class Instance < Base; end
    class PhysicalHost < Base; end
    
    class ImageStorage < Base; end
    class ImageStorageHost < Base; end
    
    class LocationGroup < Base; end
  end
end
