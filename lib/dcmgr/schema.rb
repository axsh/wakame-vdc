require 'sequel'

module Dcmgr
  module Schema
    extend self
    
    def connect(str)
      @db = Sequel.connect(str)
    end

    attr_reader :db

    def table_exists?(table_name)
      @db.table_exists? table_name
    end
    
    def create!
      Sequel::MySQL.default_engine = 'InnoDB'
      
      @db.create_table? :accounts do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        String :name
        Boolean :enable, :default=>true
        DateTime :created_at, :null=>false
        DateTime :contract_at, :null=>true
        DateTime :deleted_at, :null=>true
        Boolean :is_deleted, :default=>false
        String :memo
      end
      
      @db.create_table? :users do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        String :name, :unique=>true, :null=>false
        String :password, :null=>false
        String :default_password, :null=>false # default password, use password reset
        Boolean :enable, :default=>true
        String :email
        String :memo
      end

      @db.create_table? :accounts_users do
        Fixnum :account_id, :type=>Integer, :null=>false
        Fixnum :user_id, :type=>Integer, :null=>false
        primary_key ([:account_id, :user_id])
      end

      @db.create_table? :key_pairs do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        Fixnum :user_id, :null=>false
        String :public_key, :null=>false
      end

      @db.create_table? :image_storages do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        Fixnum :account_id, :type=>Integer, :null=>false
        Fixnum :user_id, :type=>Integer, :null=>false
        Fixnum :image_storage_host_id, :null=>false
        String :storage_url, :null=>false
        String :name, :null=>false
        Fixnum :archetype, :null=>false # 0: 32, 1: 64
      end

      @db.create_table? :image_storage_hosts do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
      end
      
      @db.create_table? :physical_hosts do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        Fixnum :cpus, :null=>false
        Float :cpu_mhz, :null=>false
        Fixnum :memory, :null=>false # MB
        String :hypervisor_type, :fixed=>true, :size=>8, :null=>false # xen, kvm, ...
        Fixnum :archetype, :null=>false # 0: 32, 1: 64
      end
      
      @db.create_table? :instances do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        Fixnum :status, :null=>false # 0: offline, 1: running, 2: online, 3: terminating
        DateTime :status_updated_at, :null=>false
        Fixnum :account_id, :type=>Integer, :null=>false
        Fixnum :user_id, :null=>false
        Fixnum :image_storage_id, :null=>false
        Fixnum :need_cpus, :null=>false
        Float :need_cpu_mhz, :null=>false
        Fixnum :need_memory, :null=>false # MB
        Fixnum :hv_agent_id, :null=>false
        Fixnum :archetype, :null=>false # 0: 32, 1: 64
      end

      @db.create_table? :ip_groups do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        String :name, :fixed=>true, :size=>32, :null=>false
      end

      @db.create_table? :ips do
        primary_key :id, :type=>Integer
        Fixnum :ip_group_id, :type=>Integer, :null=>false
        String :mac, :fixed=>true, :size=>17, :null=>false
        String :ip, :fixed=>true, :size=>14, :null=>false
        Fixnum :instance_id
        Fixnum :status, :null=>false
      end

      @db.create_table? :hv_controllers do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        String :access_url, :null=>false
      end
      
      @db.create_table? :hv_agents do
        primary_key :id, :type=>Integer
        String :uuid, :fixed=>true, :size=>8, :null=>false
        index :uuid, :unique=>true
        Fixnum :hv_controller_id
        Fixnum :physical_host_id
        String :ip, :fixed=>true, :size=>14
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

      @db.create_table? :tag_attributes do
        key :tag_id, :type=>Integer
        Fixnum :role, :null=>false # only auth tag, if name tag then 0
        File :body, :size=>:medium
      end

      @db.create_table? :tag_mappings do
        primary_key :id, :type=>Integer
        Fixnum :tag_id, :null=>false
        Fixnum :target_type, :size=>2 # 0: account, 1: name tag, 2: user, 3: instance, 4: instance image, 5: vmc, 6: physical host, 7: physical host location
        Fixnum :target_id, :null=>false
        index [:tag_id, :target_type, :target_id]
      end

      @db.create_table? :logs do
        primary_key :id, :type=>Integer
        String :fsuser, :fixed=>true, :size=>32, :null=>false
        String :target_uuid, :fixed=>true, :size=>32, :null=>false
        String :action, :fixed=>true, :size=>32, :null=>false
        Fixnum :account_id, :null=>false
        Fixnum :user_id, :null=>false
        String :message, :fixed=>true, :size=>2, :null=>false
        DateTime :created_at, :null=>false
      end

      @db.create_table? :account_logs do
        primary_key :id, :type=>Integer
        Date :target_date, :null=>false
        Fixnum :user_id, :null=>false
        Fixnum :account_id, :null=>false
        String :target_uuid, :fixed=>true, :size=>32, :null=>false
        Fixnum :use_minutes, :null=>false
        DateTime :created_at, :null=>false
      end
      
      initial_data
    end

    def initial_data
      Models::Tag.create_system_tags
    end

    def createsuperuser(name, passwd)
      Models::User.create(:name=>name, :password=>'passwd')
    end

    def load_data(path)
      if FileTest.exist? path + '.dump'
        open(path + ".dump") {|f|
          while line = f.gets
            @db << line unless line == "\n"
          end
        }
      elsif FileTest.exist? path + '.rb'
        open(path + ".rb") {|f|
          Kernel.load path + ".rb"
        }
      else
        raise "file not exists: %s" % path
      end
    end

    def drop!
      Dcmgr::logger.debug "drop tables"
      models.each { |model|
        Dcmgr::logger.debug "deleteting ... #{model.table_name}"
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
      @models ||= [Models::Account, Models::User, Models::AccountsUser,
                   Models::Instance,
                   Models::IpGroup, Models::Ip,
                   Models::ImageStorage, Models::ImageStorageHost, Models::PhysicalHost,
                   Models::HvController, Models::HvAgent,
                   Models::Tag, Models::TagAttribute, Models::TagMapping,
                   Models::Log, Models::AccountLog,
                   Models::KeyPair,
                  ].freeze
    end
  end
end

