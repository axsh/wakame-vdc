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
  foreign_key :group_id, :Groups, :null=>false
end

DB.create_table? :virtualmachinespecs do
  primary_key :id, :type=>Integer
  Float :cpu_mhz, :null=>false
  Fixnum :memory, :null=>false
end

DB.create_table? :imagestorages do
  primary_key :id, :type=>Integer
  primary_key :access_id, :auto_increment=>false, :type=>String, :fixed=>true, :size=>8
  String :storage_url, :null=>false
end

DB.create_table? :physicalmachines do
  primary_key :id, :type=>Integer
  String :cpu_model, :null=>false
  Float :cpu_mhz, :null=>false
  Fixnum :memory, :null=>false
  String :location, :null=>false
  String :hypervisor_type, :fixed=>true, :size=>8, :null=>false # xen, kvm, ...
end

DB.create_table? :instances do
  primary_key :id, :type=>Integer
  primary_key :access_id, :type=>String, :auto_increment=>false, :fixed=>true, :size=>8
  foreign_key :user_id, :Users, :null=>false
  foreign_key :physicalmachine_id, :Physicalmachines, :null=>false
  foreign_key :imagestorage_id, :Imagestorages, :null=>false
  foreign_key :virtualmachinespec_id, :Virtualmachinespecs, :null=>false
end

DB.create_table? :vmcontrollermasters do
  primary_key :id, :type=>Integer
  String :access_url, :null=>false
end

DB.create_table? :vmcontrolleragents do
  primary_key :id, :type=>Integer
  foreign_key :vmcontrollermaster_id, :Vmcontrollermasters
  foreign_key :physicalmachine_id, :Physicalmachines
end

