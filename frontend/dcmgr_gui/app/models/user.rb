# -*- coding: utf-8 -*-

require 'digest/sha1'
require 'i18n'
require 'tzinfo'

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

  def validate
    unless TZInfo::Timezone.all_identifiers.member?(self.time_zone)
      errors.add(:time_zone, "Unknown time zone identifier: #{self.time_zone}")
    end
  end
 
  def before_validation
    self[:locale] ||= I18n.default_locale.to_s
    self[:time_zone] ||= DEFAULT_TIMEZONE
    super
  end

  def before_save
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
  
  def is_system_manager?
    account = User.primary_account(self.primary_account_id)
    account.is_admin
  end
  
  # ページ指定一覧の取得
  def self.list(params)
     start = params[:start].to_i
     start = start < 1 ? 0 : start
     limit = params[:limit].to_i
     limit = limit < 1 ? nil : limit

     # 全レコードを取り込み
     total_ds = User.select_all
     # ソートして絞りこみ
     partial_ds  = total_ds.dup.order(:id.desc).limit(limit,start)
     # 結果配列初期化
     results = []
     i = 0
     # 返却ハッシュ構造を調整
     partial_ds.each{|row| results[i] = {:result => row.values };i+=1 }
     res1 = [{
            :total => total_ds.count,
            :start => start,
            :limit => limit,
            :results=> results
           }]
     res = [{:user => res1[0] }]
  end

  # ユーザ削除
  def self.delete_user(uuid)
    ds = User.filter(:uuid=>uuid)
    User.filter('uuid = ?',uuid).delete
    h = ds.first
  end

  # validation有の１レコード選択
  def self.show(uuid)
    h = self.get_user(uuid)
    h == false ? false : h.values 
  end

  # validationなしの１レコード選択
  def self.sel(uuid)
    ds = User.filter(:uuid=>uuid)
    h = ds.first
  end

  # 一致件数リターン
  def self.count(login_id)
    c = User.select_all.filter(:login_id => login_id).count
  end

  # uuidでソートして全件取得
  def self.order_all
    h = User.select_all.order(:uuid).all
  end

  # ユーザアカウント関連付けダイアログ表示用（アカウント管理）（uuidソート）
  def self.get_list(account_uuid)
    # ユーザテーブル全件と対象ユーザに紐付いたユーザレコードを外部結合
    h = @db["SELECT a.uuid,b.flg,a.id from users a LEFT OUTER JOIN (SELECT users.uuid,1 AS flg FROM accounts,users,users_accounts WHERE accounts.id = users_accounts.account_id AND users.id = users_accounts.user_id AND accounts.uuid = ? AND accounts.is_deleted = 0) b ON a.uuid = b.uuid ORDER BY uuid",account_uuid].all
  end

  # ユーザ作成
  def self.insert_user(data)
    @db.transaction do
      u = self.create(data)
      u = self.edit_user(data) 
    end
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
    
    def primary_account(account_id)
      User.find(:primary_account_id => account_id).accounts.first
    end
    
    def encrypt_password(password)
      salt = Digest::SHA1.hexdigest(SECRET_TOKEN)
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

    def edit_user(params)
      u = User.find(:login_id => params[:login_id])
      u.name = params[:name] 
      u.time_zone = params[:time_zone] 
      u.locale = params[:locale] 
      u.save
    end

    def update_pr_user(uuid,primary_account_id)
      u = User.find(:uuid => uuid)
      u.primary_account_id = primary_account_id
      u.save
    end
  end
end
