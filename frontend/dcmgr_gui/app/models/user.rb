# -*- coding: utf-8 -*-
class User < BaseNew
  taggable 'u'
  with_timestamps
  plugin :single_table_inheritance, :uuid, :model_map=>{}
  plugin :subclasses

  inheritable_schema do
    Time   :last_login_at, :null=>false
    String :name, :fixed=>true, :size=>200, :null=>false
    primary_key :id, :type=>Integer
    String :login_id, :unique=>true
    String :password, :null=>false
    String :primary_account_id
    String :locale, :size=>255, :null => false
    String :time_zone, :size=>255, :null => false
  end

  many_to_many :accounts,:join_table => :users_accounts
 
  def before_create
    set(:locale => I18n.default_locale.to_s)
    set(:time_zone => Time.zone.name)
    set(:last_login_at => Time.now.utc)
    super
  end
 
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

    def update_last_login(user_id)
      u = User.find(:id => user_id)
      u.last_login_at = Time.now
      u.save
    end

    def update_settings(user_id, params)
      u = User.find(:id => user_id)
      p params
      u.time_zone = params[:time_zone] || u.time_zone
      u.locale = params[:locale] || u.locale
      u.save
    end
  end
end
