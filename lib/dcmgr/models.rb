#!/usr/bin/ruby

require 'rubygems'
require 'sequel'

class Account < Sequel::Model;
  one_to_many :account_roll
end

class User < Sequel::Model;
  one_to_many :account_roll
end

class AccountRoll < Sequel::Model;
  many_to_one :account
  many_to_one :user
end

class Instance < Sequel::Model; end

class ImageStorage < Sequel::Model; end

class ImageStorageHost < Sequel::Model; end

class PhysicalHost < Sequel::Model; end

class HvController < Sequel::Model; end

class HvAgent < Sequel::Model; end

class Tag < Sequel::Model; end

class TagMapping < Sequel::Model; end

class Log < Sequel::Model; end
