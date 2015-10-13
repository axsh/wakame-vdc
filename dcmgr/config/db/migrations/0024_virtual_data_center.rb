# encoding: utf-8

Sequel.migration do
  up do
    create_table(:virtual_data_centers) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :account_id, "varchar(255)", :null=>false
      column :virtual_data_center_spec_id, "int(11)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime"

      index [:uuid], :unique=>true
    end

    create_table(:virtual_data_center_specs) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :account_id, "varchar(255)", :null=>false
      column :name, "varchar(255)", :null=>false
      column :file, "text", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime"

      index [:uuid], :unique=>true
    end

    alter_table(:instances) do
      add_column :virtual_data_center_id, "int(11)", :null=>true
    end
  end

  down do
    drop_table(:virtual_data_centers, :virtual_data_center_specs)

    alter_table(:instances) do
      drop_column :virtual_data_center_id
    end
  end
end
