Sequel.migration do
  up do
    create_table :notifications do
      primary_key :id
      column :uuid, "varchar(255)", :null => false
      column :title, "varchar(255)"
      column :article, "text"
      column :distribution, "varchar(255)"
      column :publish_date_to, 'datetime'
      column :publish_date_from, 'datetime'
      column :created_at, "datetime", :null => false
      column :updated_at, "datetime", :null => false
      column :deleted_at, "datetime", :null => false
    end

    create_table :notification_users do
      primary_key :id
      column :notification_id, "int(11)"
      column :user_id, "varchar(255)"
      index [:notification_id, :user_id]
    end

  end

  down do
    drop_table(:notifications, :notification_users)
  end
end
