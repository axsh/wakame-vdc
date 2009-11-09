#!/usr/bin/ruby

require 'rubygems'
require 'sequel'

require 'models'

DB.create_table? :groups do
  primary_key :id, :type=>Integer
  String :name, :unique=>true, :null=>false
end

DB.create_table? :users do
  primary_key :id, :type=>Integer
  String :account, :unique=>true, :null=>false
  String :password, :null=>false
  Fixnum :group_id, :null=>false
end

DB.create_table? :vmspecs do
  primary_key :id, :type=>Integer
  Float :cpu_mhz, :null=>false
  Fixnum :memory, :null=>false
end

DB.create_table? :imagestorages do
  primary_key :id, :type=>Integer
  String :access_id, :auto_increment=>false, :fixed=>true, :size=>8
  String :storage_url, :null=>false
end

DB.create_table? :physicalhosts do
  primary_key :id, :type=>Integer
  String :cpu_model, :null=>false
  Float :cpu_mhz, :null=>false
  Fixnum :memory, :null=>false
  String :location, :null=>false
  String :hypervisor_type, :fixed=>true, :size=>8, :null=>false # xen, kvm, ...
end

DB.create_table? :instances do
  primary_key :id, :type=>Integer
  String :access_id, :type=>String, :auto_increment=>false, :fixed=>true, :size=>8
  Fixnum :user_id, :null=>false
  Fixnum :physicalhost_id, :null=>false
  Fixnum :imagestorage_id, :null=>false
  Fixnum :vmspec_id, :null=>false
end

DB.create_table? :vmcmasters do
  primary_key :id, :type=>Integer
  String :access_url, :null=>false
end

DB.create_table? :vmcagents do
  primary_key :id, :type=>Integer
  Fixnum :vmcmaster_id
  Fixnum :physicalhost_id
end
