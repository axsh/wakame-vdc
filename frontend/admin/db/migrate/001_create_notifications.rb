Sequel.migration do
  up do
    create_table :notifications do
      primary_key :id
      column :title, "varchar(255)"
      column :article, "text"
      column :users, "text"
      column :publish_date_to, 'datetime'
      column :publish_date_from, 'datetime'
      column :created_at, "datetime", :null => false
      column :updated_at, "datetime", :null => false
      column :deleted_at, "datetime", :null => false
    end
  end

  down do
    drop_table :notifications
  end
end
