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

    alter_table(:networks) do
      add_column :gateway_network_id, "int(11)"
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

    create_table(:network_ports) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :network_id, "int(11)", :null=>false
      column :network_vif_id, "int(11)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:network_vif_id], :unique=>true
      index [:network_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    rename_table(:instance_nics, :network_vifs)

    alter_table(:network_vifs) do
      # Migrate network_id to network_ports.
      drop_column :network_id

      # add_column :network_port_id, "int(11)"
    end

    alter_table(:ip_leases) do
      rename_column :instance_nic_id, :network_vif_id

      drop_index [:instance_nic_id, :network_id]
      add_index [:network_vif_id, :network_id]
    end

    create_table(:instance_nic_join) do
      primary_key :id, :type=>"int(11)"
      column :instance_id, "int(11)", :null=>false
      column :network_vif_id, "int(11)", :null=>false

      index [:instance_id]
      index [:network_vif_id]
    end

  end
  
  down do
    drop_table(:host_node_vnets)
    drop_table(:instance_nic_join)
    drop_table(:network_ports)
    drop_table(:network_vifs)

    alter_table(:host_nodes) do
      add_column :account_id, "varchar(255)", :null=>false
    end

    alter_table(:storage_nodes) do
      add_column :account_id, "varchar(255)", :null=>false
    end
  end
end
