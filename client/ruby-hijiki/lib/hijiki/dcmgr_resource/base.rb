# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource
  @debug = false

  class << self
    attr_accessor :debug
  end
  
end

require 'active_resource'

module Hijiki::DcmgrResource::Common

  class Base < ActiveResource::Base

    # self.site = 'http://your.dcmgr.api.server'
    self.timeout = 30
    self.format = :json
    
    class << self
      
      def total_resource
        result = self.find(:first,:params => {:start => 0,:limit => 1})
        result.total
      end

      def get_resource_state_count(resources, state)
        resource_count = 0
        unless resources.empty?   
          resources.each do |item|
            if item.state == state
              resource_count += 1;
            end
          end
        end
        resource_count
      end

      def preload_resource(resource_name, compatibility_module)
        resource         = self.const_set(resource_name, Class.new(Hijiki::DcmgrResource::Base))
        resource.prefix  = self.prefix
        resource.site    = self.site

        resource.class_eval do
          include compatibility_module
        end
      end

    end
  end

  module ListMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def list(params = {})
        self.find(:all,:params => params.merge({}))
      end
      
      def show(uuid)
        self.get(uuid)
      end
    end
  end

end

ActiveResource::Connection.class_eval do

  alias :build_request_headers_orig :build_request_headers
  def build_request_headers(headers, http_method, uri)
    h = build_request_headers_orig(headers, http_method, uri)
    ra = Thread.current[:hijiki_request_attribute]
    ra.build_http_headers
    if ra
      h.update(ra.build_http_headers)
    else
      h
    end
  end
  
  def configure_http(http)
    http = apply_ssl_options(http)
    
    #add debug 
    http.set_debug_output($stderr) if Hijiki::DcmgrResource.debug
    
    # Net::HTTP timeouts default to 60 seconds.
    if @timeout
      http.open_timeout = @timeout
      http.read_timeout = @timeout
    end
    
    http
  end
end
