Sequel.migration do
  up do
    alter_table(:host_nodes) do
      # HostNode is no longer an account associated resource.
      drop_column :account_id
    end

    alter_table(:storage_nodes) do
      # StorageNode is no longer an account associated resource.
      drop_column :account_id
    end

    create_table(:host_node_vnets) do
      primary_key :id, :type=>"int(11)"
      column :host_node_id, "int(11)", :null=>false
      column :network_id, "int(11)", :null=>false
      column :broadcast_addr, "varchar(12)", :null=>false

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime"

      index [:host_node_id]
      index [:network_id]
      index [:broadcast_addr]
    end

    create_table(:network_services) do
      primary_key :id, :type=>"int(11)"
      column :network_vif_id, "int(11)"

      column :name, "varchar(255)", :null=>false
      column :incoming_port, "int(11)"
      column :outcoming_port, "int(11)"

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:network_vif_id]
      index [:network_vif_id,:name], :unique=>true
    end

    drop_table(:security_group_rules)

    rename_table(:instance_nics, :network_vifs)

    alter_table(:network_vifs) do
      set_column_allow_null :instance_id, true
      set_column_allow_null :network_id, true

      add_column :network_service_id, "int(11)"
    end

    alter_table(:ip_leases) do
      rename_column :instance_nic_id, :network_vif_id

      drop_index [:instance_nic_id, :network_id]
      add_index [:network_vif_id, :network_id]
    end

    alter_table(:images) do
      add_column :file_format, "varchar(255)", :null=>false
      add_column :root_device, "varchar(255)"
    end
  end
  
  down do
    drop_table(:host_node_vnets)
    drop_table(:network_services)

    rename_table(:network_vifs, :instance_nics)

    alter_table(:host_nodes) do
      add_column :account_id, "varchar(255)", :null=>false
    end

    alter_table(:storage_nodes) do
      add_column :account_id, "varchar(255)", :null=>false
    end

    alter_table(:images) do
      drop_column :file_format
      drop_column :root_device
    end
  end
end
