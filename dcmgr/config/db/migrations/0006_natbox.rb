Sequel.migration do
  up do
    create_table(:routes) do
      column :route_type, "int(11)", :default=>0, :null=>false

      column :inner_network_id, "int(11)", :null=>false
      column :inner_network_vif_id, "int(11)"
      column :inner_ipv4, "int(11)", :null=>false, :unsigned=>true

      column :outer_network_id, "int(11)", :null=>false
      column :outer_network_vif_id, "int(11)"
      column :outer_ipv4, "int(11)", :null=>false, :unsigned=>true

      # If false, delete when vif is disconnected from network.
      column :is_permanent, "int(11)", :default=>false, :null=>false

      index [:inner_network_id, :outer_network_id, :inner_ipv4, :outer_ipv4], :unique=>true
      index [:inner_network_id]
      index [:inner_network_vif_id]
      index [:outer_network_id]
      index [:outer_network_vif_id]
    end

    alter_table(:dhcp_ranges) do
      add_column :group, "varchar(255)"
    end

  end

  down do
    drop_table(:routes)

    alter_table(:dhcp_ranges) do
      drop_column :group
    end
  end
end
