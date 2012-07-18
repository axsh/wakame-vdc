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
        resource         = self.const_set(resource_name, Class.new(Hijiki::DcmgrResource::Common::Base))
        resource.prefix  = self.prefix
        resource.site    = self.site

        resource.class_eval do
          include compatibility_module
        end
      end

      def initialize_user_result(class_name, result_module)
        if result_module.class == Array
          new_module = Module.new do
            def user_attributes
              @@user_attributes
            end
          end

          new_module.class_variable_set(:@@user_attributes, result_module)
          result_module = new_module
        end

        if class_name.nil?
          include(result_module)
          self.preload_resource('Result', result_module)
        else
          self.preload_resource(class_name, result_module)
          self.const_get('Result').preload_resource(class_name, result_module)
        end
      end

    end

    def to_hash
      self.attributes.to_hash
    end

    def to_user_hash
      self.attributes_to_hash(self.user_attributes)
    end

    def attributes_to_hash(use_attributes)
      result = {}
      use_attributes.each { |key| result[key] = attributes[key] }
      result
    end

  end

  module ListMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def list(params = {})
        self.find(:all,:params => params.merge({:service_type=>'std'}))
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
