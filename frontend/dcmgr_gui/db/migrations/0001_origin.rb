Sequel.migration do
  up do
    create_table(:accounts, :ignore_index_errors=>true) do
      primary_key :id
      String :uuid, :null=>false, :size=>255
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      String :name, :null=>false, :size=>255
      String :description, :text=>true
      TrueClass :enabled, :default=>true
      DateTime :deleted_at
      TrueClass :is_admin, :default=>false
      
      index [:uuid], :unique=>true, :name=>:uuid
      index [:deleted_at]
    end
    
    create_table(:information) do
      primary_key :id
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      String :title, :size=>255
      String :link, :text=>true
      String :description, :text=>true
    end
    
    create_table(:oauth_consumers, :ignore_index_errors=>true) do
      primary_key :id
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      String :key, :null=>false, :size=>40
      String :secret, :null=>false, :size=>40
      Integer :account_id, :null=>false
      
      index [:account_id], :unique=>false
      index [:key], :unique=>true
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
      String :uuid, :null=>false, :size=>255
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :last_login_at, :null=>false
      String :name, :null=>false, :size=>200, :fixed=>true
      String :login_id, :null=>false, :size=>255
      String :password, :null=>false, :size=>255
      String :primary_account_id, :size=>255
      String :locale, :null=>false, :size=>255
      String :time_zone, :null=>false, :size=>255
      Boolean :enabled, :null=>false, :default=>true
      DateTime :deleted_at
      String :description, :text=>true
      
      index [:login_id], :unique=>true, :name=>:login_id
      index [:uuid], :unique=>true, :name=>:uuid
      index [:deleted_at]
    end
    
    create_table(:users_accounts) do
      primary_key :id
      Integer :user_id, :null=>false
      Integer :account_id, :null=>false
    end

    create_table(:account_quota) do
      primary_key :id
      Integer :account_id, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      String :quota_type, :null=>false
      Float :quota_value, :null=>false

      index [:account_id, :quota_type], :unique=>true
    end
  end
  
  down do
    drop_table(:accounts, :information, :oauth_consumers, :users, :users_accounts, :account_quota)
  end
end
