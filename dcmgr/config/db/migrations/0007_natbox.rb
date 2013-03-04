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

    create_table(:ip_lease_handles) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :display_name, "varchar(255)", :null=>true

      column :ip_lease_id, "int(11)", :null=>false

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true

      index [:uuid], :unique=>true, :name=>:uuid
      index [:deleted_at]
    end

    create_table(:network_routes) do
      primary_key :id, :type=>"int(11)"

      column :route_type, "varchar(255)", :null=>false

      column :inner_network_id, "int(11)", :null=>false
      column :inner_vif_id, "int(11)"
      column :inner_ipv4, "int(11)", :unsigned=>true

      column :outer_network_id, "int(11)", :null=>false
      column :outer_vif_id, "int(11)"
      column :outer_ipv4, "int(11)", :unsigned=>true

      # If false, delete when vif is disconnected from network.
      column :is_permanent, "int(11)", :default=>false, :null=>false
      column :is_deleted, "int(11)", :null=>false

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true

      index [:inner_network_id, :outer_network_id, :inner_ipv4, :outer_ipv4, :is_deleted], :unique=>true, :name => 'nw_vif_index'
    end

  end

  down do
    drop_table(:ip_pools)
    drop_table(:ip_pool_dc_networks)
    drop_table(:ip_lease_handles)
    drop_table(:network_routes)
  end
end
