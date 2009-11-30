
require 'rubygems'
require 'sequel'

module Wakame
  module Dcmgr
    module Schema
      extend self

      def connect(str)
        @db = Sequel.connect(str)
      end
      
      def load
        require 'wakame-dcmgr/models'
      end
      
      def create!
        @db.create_table? :groups do
          primary_key :id, :type=>Integer
          String :name, :unique=>true, :null=>false
        end

        @db.create_table? :users do
          primary_key :id, :type=>Integer
          String :account, :unique=>true, :null=>false
          String :password, :null=>false
          Fixnum :group_id, :null=>false
        end
        
        @db.create_table? :hv_specs do
          primary_key :id, :type=>Integer
          Float :cpu_mhz, :null=>false
          Fixnum :memory, :null=>false
        end
        
        @db.create_table? :image_storages do
          primary_key :id, :type=>Integer
          Fixnum :imagestoragehost_id, :null=>false
          String :access_id, :fixed=>true, :size=>8, :null=>false
          String :storage_url, :null=>false
        end

        @db.create_table? :image_storage_hosts do
          primary_key :id, :type=>Integer
        end
        
        @db.create_table? :physical_hosts do
          primary_key :id, :type=>Integer
          String :cpu_model, :null=>false
          Float :cpu_mhz, :null=>false
          Fixnum :memory, :null=>false
          String :location, :null=>false
          String :hypervisor_type, :fixed=>true, :size=>8, :null=>false # xen, kvm, ...
          Fixnum :relate_user_id
        end
        
        @db.create_table? :instances do
          primary_key :id, :type=>Integer
          String :access_id, :type=>String, :fixed=>true, :size=>8, :null=>false
          Fixnum :user_id, :null=>false
          Fixnum :physicalhost_id, :null=>false
          Fixnum :imagestorage_id, :null=>false
          Fixnum :hvspec_id, :null=>false
        end
        
        @db.create_table? :hv_controllers do
          primary_key :id, :type=>Integer
          String :access_url, :null=>false
        end
        
        @db.create_table? :hv_agents do
          primary_key :id, :type=>Integer
          Fixnum :hvcontroller_id
          Fixnum :physicalhost_id
        end

        require 'wakame-dcmgr/models'
      end

      def drop!
        models.each { |model|
          @db.drop_table(model.table_name)
        }
      end

      def table_exists?(table_name)
        @db.table_exists? table_name
      end

      def models
        require 'wakame-dcmgr/models'
        @models ||= [Group, User,
                     Instance, ImageStorage, HvSpec, PhysicalHost,
                     HvController, HvAgent, ].freeze
      end
    end
  end
end
