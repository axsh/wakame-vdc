#!/usr/bin/ruby

require 'rubygems'
require 'sequel'

module Dcmgr
  class Model < Sequel::Model
    class InvalidUUIDException < Exception; end
    
    def generate_uuid
      "%08x" % rand(16 ** 8)
    end

    def self.search_by_uuid(uuid)
      self.filter

    def before_create
      begin

          self.name = User.generate_name unless self.name
          self.access_id = User.generate_accesskey
          user = self
        rescue
      user = nil
        end until user
      end
    end

    def uuid
      "%s-%s" % [self.class.prefix, self.super.uuid]
    end

    def trim_uuid
      uuid = self.super.uuid
      if uuid and uuid.length == self.class.prefix.length + 9
        uuid[self.class.prefix.length ... -1]
      else
        raise InvalidUUIDException
      end
    end
  end
end

class Account < Dcmgr::Model
  def self.prefix_uuid; 'A'; end
  one_to_many :account_roll
end

class User < Dcmgr::Model
  def self.prefix_uuid; 'U'; end
  one_to_many :account_roll
end

class AccountRoll < Sequel::Model
  many_to_one :account
  many_to_one :user
end

class Instance < Dcmgr::Model
  def self.prefix_uuid; 'I'; end
end

class ImageStorage < Dcmgr::Model
  def self.prefix_uuid; 'IS'; end
end

class ImageStorageHost < Dcmgr::Model
  def self.prefix_uuid; 'ISH'; end
end

class PhysicalHost < Dcmgr::Model
  def self.prefix_uuid; 'PH'; end
end

class HvController < Dcmgr::Model
  def self.prefix_uuid; 'HVC'; end
end

class HvAgent < Dcmgr::Model
  def self.prefix_uuid; 'HVA'; end
end

class Tag < Dcmgr::Model
  def self.prefix_uuid; 'TAG'; end
end

class TagMapping < Sequel::Model; end

class Log < Sequel::Model; end
