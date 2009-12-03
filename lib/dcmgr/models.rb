#!/usr/bin/ruby

require 'rubygems'
require 'sequel'

module Dcmgr::Model
  class InvalidUUIDException < Exception; end

  module UUIDMethods
    def generate_uuid
      "%08x" % rand(16 ** 8)
    end

    def self.search_by_uuid(uuid)
      self.filter

    end

    def setup_uuid
      self.uuid = generate_uuid
    end

    def before_create
      setup_uuid
    end

    def uuid
      "%s-%s" % [self.prefix_uuid, self.values[:uuid]]
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

class Account < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def prefix_uuid; 'A'; end
  one_to_many :account_roll
end

class User < Sequel::Model
  include Dcmgr::Model::UUIDMethods
  def prefix_uuid; 'U'; end
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
  def prefix_uuid; 'TAG'; end
end

class TagMapping < Sequel::Model; end

class Log < Sequel::Model; end
