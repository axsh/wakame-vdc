Sequel.migration do
  up do
    create_table(:network_routes) do
      column :route_type, "int(11)", :default=>0, :null=>false

      column :i_network_id, "int(11)", :null=>false
      column :i_network_vif_id, "int(11)"
      column :i_ipv4, "int(11)", :null=>false, :unsigned=>true

      column :o_network_id, "int(11)", :null=>false
      column :o_network_vif_id, "int(11)"
      column :o_ipv4, "int(11)", :null=>false, :unsigned=>true

      # If false, delete when vif is disconnected from network.
      column :is_permanent, "int(11)", :default=>false, :null=>false

      index [:i_network_id, :o_network_id, :i_ipv4, :o_ipv4], :unique=>true
      index [:i_network_id]
      index [:i_network_vif_id]
      index [:o_network_id]
      index [:o_network_vif_id]
    end

    alter_table(:dhcp_ranges) do
      add_column :group, "varchar(255)"
    end

  end

  down do
    drop_table(:network_routes)

    alter_table(:dhcp_ranges) do
      drop_column :group
    end
  end
end
