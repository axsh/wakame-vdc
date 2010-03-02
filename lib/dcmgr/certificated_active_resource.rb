require 'active_resource'

# Custom Active Resource Class, add request header parameter user_uuid
#
# sample:
# class A < Dcmgr::CertificatedActiveResource
#   self.user_uuid = 'abc'
#   self.site = xxxx
# end

module Dcmgr
  class CertificatedActiveResource < ActiveResource::Base
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
end

 
