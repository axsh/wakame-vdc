Sequel.migration do
  up do
    create_table :notifications do
      primary_key :id
      column :uuid, "varchar(255)", :null => false
      column :title, "varchar(255)"
      column :article, "text"
      column :distribution, "varchar(255)"
      column :display_end_at, 'datetime'
      column :display_begin_at, 'datetime'
      column :created_at, "datetime", :null => false
      column :updated_at, "datetime", :null => false
      column :deleted_at, "datetime", :null => false
    end

    create_table :notification_users do
      primary_key :id
      column :notification_id, "int(11)", :null => false
      column :user_id, "int(11)", :null => false
      index [:notification_id, :user_id]
    end

  end

  down do
    drop_table(:notifications, :notification_users)
  end
end
