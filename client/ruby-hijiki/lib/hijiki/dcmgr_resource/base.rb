# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource
  @debug = false

  class << self
    attr_accessor :debug
  end
  
end

require 'active_resource'
require 'hijiki/dcmgr_resource/errors'

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

      def initialize_user_result(class_name, arg, hash_attrs = nil, list_attrs = nil)
        if arg.class == Array
          result_module = Module.new
          user_attr = arg
          arg = result_module

          result_module.send(:define_method, :user_attributes) do
            user_attr
          end
          result_module.send(:define_method, :user_hash_attributes) do
            hash_attrs
          end
          result_module.send(:define_method, :user_list_attributes) do
            list_attrs
          end
        end

        if class_name.nil?
          include(arg)
          self.preload_resource('Result', arg)
        else
          self.preload_resource(class_name, arg)
          self.const_get('Result').preload_resource(class_name, arg)
        end
      end

    end

    def to_hash
      self.attributes.to_hash
    end

    def to_user_hash
      result = self.attributes_to_hash(self.user_attributes)
      self.user_hash_attributes.each { |key| result[key] = attributes[key].to_user_hash } if self.user_hash_attributes
      self.user_list_attributes.each { |key| result[key] = attributes[key].collect { |i| i.to_user_hash } } if self.user_list_attributes
      result
    end

    def attributes_to_hash(value_attributes)
      result = {}
      value_attributes.each { |key| result[key] = attributes[key] }
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

  E = Hijiki::DcmgrResource::Errors

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

  # Handles response and error codes from the remote service.
  def handle_response(response)
    case response.code.to_i
    when 301,302
      raise(Redirection.new(response))
    when 200...400
      response
    when 400
      raise(E::BadRequest.new(response))
    when 401
      raise(E::UnauthorizedAccess.new(response))
    when 403
      raise(E::ForbiddenAccess.new(response))
    when 404
      raise(E::ResourceNotFound.new(response))
    when 405
      raise(MethodNotAllowed.new(response))
    when 409
      raise(E::ResourceConflict.new(response))
    when 410
      raise(E::ResourceGone.new(response))
    when 422
      raise(ResourceInvalid.new(response))
    when 401...500
      raise(E::ClientError.new(response))
    when 500...600
      raise(E::ServerError.new(response))
    else
      raise(ConnectionError.new(response, "Unknown response code: #{response.code}"))
    end
  end
end
