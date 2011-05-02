# -*- coding: utf-8 -*-
class User < BaseNew
  taggable 'u'
  with_timestamps
  plugin :single_table_inheritance, :uuid, :model_map=>{}
  plugin :subclasses

  inheritable_schema do
    String :name, :fixed=>true, :size=>200, :null=>false
    primary_key :id, :type=>Integer
    String :login_id
    String :password, :null=>false
    String :primary_account_id
  end

  many_to_many :accounts,:join_table => :users_accounts
  
  # Removes all relations to accounts before deleting the record
  def before_destroy
    relations = self.accounts
    for ss in 0...relations.length do
      self.remove_account(relations[0])		  
    end
    super
  end
  
  class << self
    def authenticate(login_id,password)
      return nil if login_id.nil? || password.nil?
      u = User.find(:login_id=>login_id, :password => encrypt_password(password))
      u.nil? ? false : u
    end

    def get_user(uuid)
      return nil if uuid.nil?
      u = User.find(:uuid=>uuid)
      u.nil? ? false : u
    end
    
    def account_name_with_uuid(uuid)
      h = Hash.new
      User.find(:uuid => uuid).accounts.each{|row| h.store(row.name,row.uuid) }
      h
    end
    
    def primary_account_id(uuid)
      User.find(:uuid => uuid).primary_account_id
    end
    
    def encrypt_password(password)
      salt = Digest::SHA1.hexdigest(DcmgrGui::Application.config.secret_token)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
  end
end
