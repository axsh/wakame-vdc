Sequel.migration do
  up do
    alter_table(:host_nodes) do
      add_column :deleted_at, "datetime"

      add_index :deleted_at
    end

    alter_table(:storage_nodes) do
      add_column :deleted_at, "datetime"

      add_index :deleted_at
    end

    create_table(:network_ports) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :network_id, "int(11)", :null=>false
      column :instance_nic_id, "int(11)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
    end
  end
  
  down do
    drop_table(:network_ports)
  end
end
