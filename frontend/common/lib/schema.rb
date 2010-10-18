# -*- coding: utf-8 -*-
require 'sequel'
require 'yaml'
require 'erb'

module Frontend
  module Schema
    extend self
    
    def connect(str)
      @db = Sequel.connect(str)
    end
    
    def config(env,file)
      YAML::load(ERB.new(IO.read(file)).result)[env]
    end
      
    attr_reader :db
    def table_exists?(table_name)
      @db.table_exists? table_name
    end

    def create!
      Sequel::MySQL.default_charset = 'utf8'
      Sequel::MySQL.default_engine = 'InnoDB'

      @db.create_table? :accounts do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        String :name
        Boolean :enable, :default=>true
        DateTime :deleted_at, :null=>true
        Boolean :is_deleted, :default=>false
      end

      @db.create_table? :users_accounts do
        primary_key :id, :type=>Integer
        Fixnum :user_id, :null => false
        Fixnum :account_id, :null => false
      end

      @db.create_table? :users do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        String :login_id
        String :password, :null=>false
        String :primary_account_id
      end

      @db.create_table? :authzs do
        primary_key :id, :type=>Integer
        Fixnum :user_id, :null => false
        Fixnum :account_id, :null => false
        Fixnum :type_id, :null => false
      end
      
      @db.create_table? :tags do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        Fixnum :account_id, :null=>false # if 0 system tag
        index :account_id
        Fixnum :owner_id, :null=>false
        String :name, :fixed=>true, :size=>32, :null=>false
      end
      
      @db.create_table? :tag_mappings do
        primary_key :id, :type=>Integer
        Fixnum :tag_id, :null=>false
        Fixnum :target_type, :size=>2 # see Dcmgr::Models::TagMapping::TYPE_XXXX
        Fixnum :target_id, :null=>false
        index [:tag_id, :target_type, :target_id]
      end
      
      
    end

    def drop!
      models.each { |model|
              begin
                @db.drop_table(model.table_name)
              rescue
              end
            }
    end

    def models
      @models ||= [Models::Account, Models::User,
                   Models::Authz,Models::Tag,Models::TagMapping
                  ].freeze
    end
  end
end