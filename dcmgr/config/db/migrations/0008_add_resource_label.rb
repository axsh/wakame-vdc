# encoding: utf-8

Sequel.migration do
  up do
    create_table(:resource_labels) do
      primary_key :id, :type=>"int(11)"
      column :resource_uuid, "varchar(255)", :null=>true
      column :name, "varchar(255)", :null=>false
      column :value_type, "int(11)", :null=>false
      column :string_value, "varchar(255)", :null=>true
      column :blob_value, "text", :null=>true

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:resource_uuid, :name], :unique=>true
      index [:string_value]
    end
  end

  down do
    drop_table(:resource_labels)
  end
end
