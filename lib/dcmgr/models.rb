#!/usr/bin/ruby

require 'rubygems'
require 'sequel'

module Dcmgr::Model
  class InvalidUUIDException < Exception; end

  module UUIDMethods
    module ClassMethods
      def search_by_uuid(uuid)
        self[:uuid=>trim_uuid(uuid)]
      end
          
      def trim_uuid(p_uuid)
        if p_uuid and p_uuid.length == self.prefix_uuid.length + 9
          return p_uuid[(self.prefix_uuid.length+1), p_uuid.length]
        end
        raise InvalidUUIDException
      end
    end
    
    def self.included(mod)
      mod.extend ClassMethods
    end
      
    def generate_uuid
      "%08x" % rand(16 ** 8)
    end

    def setup_uuid
      self.uuid = generate_uuid
    end

    def before_create
      setup_uuid
    end

    def uuid
      "%s-%s" % [self.class.prefix_uuid, self.values[:uuid]]
    end
  end
end

class Account < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'A'; end
  one_to_many :account_roll
end

class User < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'U'; end
  one_to_many :account_roll
end

class AccountRoll < Sequel::Model
  many_to_one :account
  many_to_one :user
end

class Instance < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def prefix_uuid; 'I'; end
end

class ImageStorage < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def prefix_uuid; 'IS'; end
end

class ImageStorageHost < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def prefix_uuid; 'ISH'; end
end

class PhysicalHost < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def prefix_uuid; 'PH'; end
end

class HvController < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def prefix_uuid; 'HVC'; end
end

class HvAgent < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def prefix_uuid; 'HVA'; end
end

class Tag < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'TAG'; end

  TYPE_NORMAL = 0
  TYPE_AUTH = 1
  
  AUTH_TARGET_TYPE_ACCOUNT = 0
  AUTH_TARGET_TYPE_USER = 1
  AUTH_TARGET_TYPE_INSTANCE = 2
  AUTH_TARGET_TYPE_INSTANCE_IMAGE = 3
  AUTH_TARGET_TYPE_VMC = 4
  
  many_to_one :account
  
  def before_create
    super
    self.tag_type = TYPE_NORMAL unless self.tag_type
  end
end

class TagMapping < Sequel::Model; end

class Log < Sequel::Model; end
