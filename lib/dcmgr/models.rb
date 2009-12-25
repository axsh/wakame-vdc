#!/usr/bin/ruby

require 'rubygems'
require 'sequel'

module Dcmgr::Model
  class InvalidUUIDException < Exception; end

  module UUIDMethods
    module ClassMethods
      # override [] method. add search by uuid String
      def [](*args)
        if args.size == 1 and args[0].is_a? String
          super(:uuid=>trim_uuid(args[0]))
        else
          super(*args)
        end
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

class TagMapping < Sequel::Model
  TYPE_ACCOUNT = 0
  TYPE_TAG = 1
  TYPE_USER = 2
  TYPE_INSTANCE = 3
  TYPE_INSTANCE_IMAGE = 4
  TYPE_VMC = 5
  TYPE_PHYSICAL_HOST = 6
  TYPE_PHYSICAL_HOST_LOCATION = 7
end

class Account < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'A'; end

  one_to_many :account_roll
  many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_ACCOUNT}
  
  def before_create
    super
    self.exclusion = 'n' unless self.exclusion
    self.enable = 'y' unless self.enable
    self.created_at = Time.now unless self.created_at
  end
end

class User < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'U'; end

  one_to_many  :account_rolls
  many_to_many :accounts, :join_table=>:account_rolls
  many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_USER}
end

class AccountRoll < Sequel::Model
  many_to_one :account
  many_to_one :user, :left_primary_key=>:user_id
end

class Instance < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'I'; end
  
  STATUS_TYPE_STOP = 0
  STATUS_TYPE_WAIT_RUNNING = 1
  STATUS_TYPE_RUNNING = 2
  STATUS_TYPE_WAIT_SHUTDOWN = 3
  
  many_to_one :account
  many_to_one :user

  many_to_one :physical_host
  many_to_one :image_storage
  
  many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_INSTANCE}

  def before_create
    super
    self.status = STATUS_TYPE_STOP
  end

  def validate
    errors.add(:account, "can't empty") unless self.account
    errors.add(:user, "can't empty") unless self.user
    errors.add(:physical_host, "can't empty") unless self.physical_host
    errors.add(:image_storage, "can't empty") unless self.image_storage
  end
end

class ImageStorage < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'IS'; end

  many_to_one :image_storage_host
end

class ImageStorageHost < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'ISH'; end
end

class PhysicalHost < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'PH'; end
  
  many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_PHYSICAL_HOST}
  many_to_many :location_tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_PHYSICAL_HOST_LOCATION}
end

class HvController < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'HVC'; end
end

class HvAgent < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'HVA'; end
end

class Tag < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def self.prefix_uuid; 'TAG'; end

  TYPE_NORMAL = 0
  TYPE_AUTH = 1
  
  many_to_one :account
  one_to_many :tag_mappings
  many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_TAG}
  
  def before_create
    super
    self.tag_type = TYPE_NORMAL unless self.tag_type
  end
end

class Log < Sequel::Model; end
