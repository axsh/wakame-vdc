
require 'rubygems'
require 'sequel'

module Dcmgr
  module Schema
    extend self
    
    def connect(str)
      @db = Sequel.connect(str)
      load
    end
    
    def load
      require 'dcmgr/models'
      require 'dcmgr/web'
    end
    
    def create!
      @db.create_table? :accounts do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
        String :name
      end
      
      @db.create_table? :users do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
        String :account, :unique=>true, :null=>false
        String :password, :null=>false
      end

      @db.create_table? :account_rolls do
        Fixnum :account_id, :type=>Integer, :null=>false
        Fixnum :user_id, :type=>Integer, :null=>false
        index :account_id
        index :user_id
      end

      @db.create_table? :image_storages do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
        Fixnum :imagestoragehost_id, :null=>false
        String :storage_url, :null=>false
      end

      @db.create_table? :image_storage_hosts do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
      end
      
      @db.create_table? :physical_hosts do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
        String :cpu_model, :null=>false
        Float :cpu_mhz, :null=>false
        Fixnum :memory, :null=>false
        String :location, :null=>false
        String :hypervisor_type, :fixed=>true, :size=>8, :null=>false # xen, kvm, ...
        Fixnum :relate_user_id
      end
      
      @db.create_table? :instances do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
        Fixnum :user_id, :null=>false
        Fixnum :physicalhost_id, :null=>false
        Fixnum :imagestorage_id, :null=>false
        Fixnum :hvspec_id, :null=>false
      end
      
      @db.create_table? :hv_controllers do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
        String :access_url, :null=>false
      end
      
      @db.create_table? :hv_agents do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
        Fixnum :hvcontroller_id
        Fixnum :physicalhost_id
      end

      @db.create_table? :tags do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid
        Fixnum :account_id
        Fixnum :owner_id
        String :name, :fixed=>true, :size=>32
        Fixnum :tag_type, :fixed=>true, :size=>1 # 0: name tag, 1: auth tag
        Fixnum :auth_type # 0: account, 1: user, 2: instance, 3: instance image, 4: vmc
        Fixnum :auth_action
        index :account_id
      end

      @db.create_table? :tag_mappings do
        primary_key :tag_id, :type=>Integer
        Fixnum :type, :size=>2 # 0: account, 1: user, 2: instance, 3: instance image, 4: vmc
        Fixnum :target_id
        index [:tag_id, :type, :target_id]
      end

      @db.create_table? :tag_includes do
        primary_key :tag_id, :type=>Integer
        Fixnum :type, :size=>2 # 0: account, 1: user, 2: instance, 3: instance image, 4: vmc
        Fixnum :target_id
        index [:tag_id, :type, :target_id]
      end

      @db.create_table? :logs do
        primary_key :id, :type=>Integer
        String :target, :fixed=>true, :size=>32, :null=>false
        String :action, :fixed=>true, :size=>32, :null=>false
        Fixnum :user_id, :null=>false
        String :message, :fixed=>true, :size=>2, :null=>false
        DateTime :created_at, :null=>false
      end
      
      load
    end

    def drop!
      puts "drop tables"
      models.each { |model|
        puts "deleteting ... #{model.table_name}"
        begin
          @db.drop_table(model.table_name)
        rescue
        end
      }
    end

    def table_exists?(table_name)
      @db.table_exists? table_name
    end

    def models
      load
      @models ||= [Account, User, AccountRoll,
                   Instance, ImageStorage, ImageStorageHost, PhysicalHost,
                   HvController, HvAgent,
                   Tag, TagMapping,
                   Log,
                  ].freeze
    end
  end
end

