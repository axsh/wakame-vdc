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
    String :name, :null=>false
    String :description, :default=>""
    Boolean :enable, :default=>true
    DateTime :deleted_at, :null=>true
    Boolean :is_deleted, :default=>false
  end

  one_to_many  :tags
  many_to_many :users,:join_table => :users_accounts
  
  def disable?
    not self.enable
  end

  def enable?
    self.enable
  end

  def to_hash_document
    h = self.values.dup
    h[:id] = h[:uuid] = self.canonical_uuid
    h
  end

  # Delete relations before setting an account to deleted
  def before_destroy
    relations = self.users
    for ss in 0...relations.length do
      self.remove_user(relations[0])		  
    end
    
    super
  end
  
  # override Sequel::Model#_delete not to delete rows but to set
  # delete flags.
  def _delete
    self.deleted_at ||= Time.now
    self.is_deleted = true
    self.save
  end

  def self.all_accounts_with_prefix
      h = Hash.new
      Account._select_all.each{|row| h.store(row.name,'a-' + row.uuid) }
      h
  end

  # 論理削除を除く全件取得
  def self._select_all
    ds = Account.select_all.filter(:is_deleted => false)
  end

  # ページ指定一覧の取得
  def self.list(params)
     start = params[:start].to_i
     start = start < 1 ? 0 : start
     limit = params[:limit].to_i
     limit = limit < 1 ? nil : limit

     # 全レコードを取り込み
     total_ds = Account._select_all
     # ソートして絞りこみ
     partial_ds  = total_ds.dup.order(:id.desc).limit(limit,start)
     # 結果配列初期化
     results = []
     i = 0
     # 返却ハッシュ構造を調整
     partial_ds.each{|row| results[i] = {:result => row.values };i+=1 }
     res1 = [{
            :owner_total => total_ds.count,
            :start => start,
            :limit => limit,
            :results=> results
           }]
     res = [{:account => res1[0] }]
  end

  # validation有の１レコード
  def self.show(uuid)
    h = Account.find(:uuid=>uuid)
    h == false ? false : h.values 
  end

  # validationなしの１レコード選択
  def self.sel(uuid)
    ds = Account.filter(:uuid=>uuid)
    h = ds.first
  end

  # 全件取得
  def self.all
    h = Account._select_all.all
  end

  # uuidでソートして全件取得
  def self.order_all
    h = Account._select_all.order(:uuid).all
  end

  # ユーザアカウント関連付けダイアログ表示用（ユーザ管理）（uuidソート、論理削除除く）
  def self.get_list(user_uuid)
    # アカウントテーブル全件と対象ユーザに紐付いたアカウントレコードを外部結合
    h = @db["SELECT a.uuid,b.flg,a.id from accounts a LEFT OUTER JOIN (SELECT accounts.uuid,1 AS flg FROM accounts,users,users_accounts WHERE accounts.id = users_accounts.account_id AND users.id = users_accounts.user_id AND users.uuid = ? AND accounts.is_deleted = 0) b ON a.uuid = b.uuid WHERE is_deleted = 0 ORDER BY uuid",user_uuid].all
  end

  # ユーザーアカウント追加用
  def self.add_relation(user_id,account_id)
    ds = @db[:users_accounts].select_all
    ds.insert(:user_id => user_id,:account_id => account_id)
  end

  # ユーザーアカウント削除用
  def self.delete_relation(user_id,account_id)
    ds = @db[:users_accounts].select_all
    ds.filter("user_id = ? and account_id = ?",user_id,account_id).delete
  end

  # ユーザーアカウント　リンク更新（トランザクション更新）
  def self.change_relations(add_links,del_links)
    @db.transaction do
      for i in 1..(add_links.size - 1)
        h = add_links[i]
        self.add_relation(h[:user_id],h[:group_id])
      end
      for i in 1..(del_links.size - 1)
        h = del_links[i]
        self.delete_relation(h[:user_id],h[:group_id])
      end
    end
  end

  # アカウント削除（論理削除）
  def self.delete_account(uuid)
    u = Account.find(:uuid=>uuid)
    u.deleted_at ||= Time.now
    u.is_deleted = true
    u.save
  end

  # 新規アカウント追加
  def self.insert_account(data)
    # 名称が同一で、論理削除済みのアカウントを検索
    ds = Account.select_all.filter(:name => data[:name],:is_deleted => true)
    if ds.count == 0 then
      # 存在しない場合は新規追加
      self.create(data)
    else
      # 存在する場合は同名論理削除レコードを復活
      h = ds.update(:description => data[:description],:is_deleted => false,:deleted_at => nil)
    end
  end

  def self.edit_account(params)
     u = Account.find(:name => params[:name])
     u.description = params[:description] || u.descritption
     u.save
  end

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
