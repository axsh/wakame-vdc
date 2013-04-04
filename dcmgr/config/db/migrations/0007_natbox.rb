Sequel.migration do
  up do
    create_table(:ip_pools) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :display_name, "varchar(255)", :null=>true

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true

      index [:uuid], :unique=>true, :name=>:uuid
      index [:account_id]
      index [:deleted_at]
    end

    create_table(:ip_pool_dc_networks) do
      primary_key :id, :type=>"int(11)"

      column :ip_pool_id, "int(11)", :null=>false
      column :dc_network_id, "int(11)", :null=>false
      
      index [:ip_pool_id, :dc_network_id], :unique=>true
    end

    create_table(:ip_handles) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :display_name, "varchar(255)", :null=>true
      column :ip_pool_id, "int(11)", :null=>false

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true

      index [:uuid], :unique=>true, :name=>:uuid
      index [:deleted_at]
    end      

    create_table(:network_routes) do
      primary_key :id, :type=>"int(11)"
      column :route_type, "varchar(255)", :null=>false

      column :inner_lease_id, "int(11)", :null=>false
      column :outer_lease_id, "int(11)", :null=>false

      column :release_outer_vif, "tinyint(1)", :default=>false, :null=>false
      column :release_inner_vif, "tinyint(1)", :default=>false, :null=>false

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true
      column :is_deleted, "int(11)", :null=>false

      index [:inner_lease_id, :outer_lease_id, :is_deleted], :unique=>true
      index [:deleted_at]
    end

    alter_table(:network_vif_ip_leases) do
      add_column :ip_handle_id, "int(11)", :null=>true

      set_column_allow_null :network_vif_id, true

      add_index [:ip_handle_id, :is_deleted]
    end

  end

  down do
    drop_table(:ip_pools)
    drop_table(:ip_handles)
    drop_table(:ip_pool_dc_networks)
    drop_table(:network_routes)

    alter_table(:network_vif_ip_leases) do
      drop_column :ip_handle_id

      set_column_allow_null :network_vif_id, false

      drop_index [:ip_handle_id, :is_deleted]
    end
  end
end
