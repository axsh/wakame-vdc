Sequel.migration do
  up do
    create_table(:accounts, :ignore_index_errors=>true) do
      primary_key :id
      String :uuid, :null=>false, :size=>8, :fixed=>true
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      String :name, :null=>false, :size=>255
      String :description, :size=>255
      TrueClass :enable, :default=>true
      DateTime :deleted_at
      TrueClass :is_deleted, :default=>false
      TrueClass :is_admin, :default=>false
      
      index [:uuid], :unique=>true, :name=>:uuid
    end
    
    create_table(:authzs) do
      primary_key :id
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      Integer :user_id, :null=>false
      Integer :account_id, :null=>false
      Integer :type_id, :null=>false
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
      
      index [:account_id], :unique=>true, :name=>:account_id
      index [:key], :unique=>true
    end
    
    create_table(:tag_mappings, :ignore_index_errors=>true) do
      primary_key :id
      Integer :tag_id, :null=>false
      Integer :target_type
      Integer :target_id, :null=>false
      
      index [:tag_id, :target_type, :target_id]
    end
    
    create_table(:tags, :ignore_index_errors=>true) do
      primary_key :id
      String :uuid, :null=>false, :size=>8, :fixed=>true
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      Integer :account_id, :null=>false
      Integer :owner_id, :null=>false
      String :name, :null=>false, :size=>32, :fixed=>true
      
      index [:account_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
      String :uuid, :null=>false, :size=>8, :fixed=>true
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      DateTime :last_login_at, :null=>false
      String :name, :null=>false, :size=>200, :fixed=>true
      String :login_id, :size=>255
      String :password, :null=>false, :size=>255
      String :primary_account_id, :size=>255
      String :locale, :null=>false, :size=>255
      String :time_zone, :null=>false, :size=>255
      
      index [:login_id], :unique=>true, :name=>:login_id
      index [:uuid], :unique=>true, :name=>:uuid
    end
    
    create_table(:users_accounts) do
      primary_key :id
      Integer :user_id, :null=>false
      Integer :account_id, :null=>false
    end
  end
  
  down do
    drop_table(:accounts, :authzs, :information, :oauth_consumers, :tag_mappings, :tags, :users, :users_accounts)
  end
end
