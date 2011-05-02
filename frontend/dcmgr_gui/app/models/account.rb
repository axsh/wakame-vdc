# -*- coding: utf-8 -*-
class Account < BaseNew
  taggable 'a'
  with_timestamps
  plugin :single_table_inheritance, :uuid, :model_map=>{}
  plugin :subclasses

  # pk has to be overwritten by the STI subclasses.
  unrestrict_primary_key

  DISABLED=0
  ENABLED=1
  
  inheritable_schema do
    primary_key :id, :type=>Integer
    String :name
    Boolean :enable, :default=>true
    DateTime :deleted_at, :null=>true
    Boolean :is_deleted, :default=>false
  end

  one_to_many  :tags
  many_to_many :users,:join_table => :users_accounts
  
  def disable?
    self.enabled == DISABLED
  end

  def enable?
    self.enabled == ENABLED
  end

  def to_hash_document
    h = self.values.dup
    h[:id] = h[:uuid] = self.canonical_uuid
    h
  end

  # This method makes sure that when destroy is called, the record isn't actually deleted but just flagged as deleted.
  # All it's relations do get deleted though.
  #def before_destroy
    #relations = self.users
    #for ss in 0...relations.length do
      #puts "Deleting association with user #{relations[0].uuid}." #if options[:verbose]
      #self.remove_user(relations[0])		  
    #end
    
    #time = Time.new()
    #now  = Sequel.string_to_datetime "#{time.year}-#{time.month}-#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
    
    #self.is_deleted = true
    #self.deleted_at = now
    
    #false
  #end

  # STI class variable setter, getter methods.
  class << self
    def default_values
      @default_values ||= {}
    end

    def pk(pk=nil)
      if pk
        default_values[:id] = pk
      end
      default_values[:id]
    end
    
    def uuid(uuid=nil)
      if uuid.is_a?(String)
        uuid = uuid.downcase
        unless self.check_trimmed_uuid_format(uuid)
          raise "Invalid syntax of uuid: #{uuid}"
        end
        default_values[:uuid] = uuid
      end
      default_values[:uuid] || raise("#{self}.uuid is unset. Set the unique number")
    end

    def description(description=nil)
      if description
        default_values[:description] = description
      end
      default_values[:description]
    end
  end

  module SystemAccount
    def self.define_account(class_name, &blk)
      unless class_name.is_a?(Symbol) || class_name.is_a?(String)
        raise ArgumentError
      end

      c = Class.new(Account, &blk)
      self.const_set(class_name.to_sym, c)
      Account.sti_model_map[c.uuid] = c
      Account.sti_key_map[c.to_s] = c.uuid
      c
    end
  end

  install_data_hooks do
    Account.subclasses.each { |m|
      Account.create(m.default_values.dup)
    }
  end

  SystemAccount.define_account(:DatacenterAccount) do
    pk 100
    uuid '00000000'
    description 'datacenter system account'

    # DatacenterAccount never be disabled
    def before_save
      super
      self.enabled = Account::ENABLED
    end
  end
  
end
