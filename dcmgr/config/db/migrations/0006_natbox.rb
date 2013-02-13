Sequel.migration do
  up do
    create_table(:network_routes) do
      primary_key :id, :type=>"int(11)"

      column :route_type, "varchar(255)", :null=>false

      column :inner_network_id, "int(11)", :null=>false
      column :inner_vif_id, "int(11)"
      column :inner_ipv4, "int(11)", :null=>false, :unsigned=>true

      column :outer_network_id, "int(11)", :null=>false
      column :outer_vif_id, "int(11)"
      column :outer_ipv4, "int(11)", :null=>false, :unsigned=>true

      # If false, delete when vif is disconnected from network.
      column :is_permanent, "int(11)", :default=>false, :null=>false

      index [:inner_network_id, :outer_network_id, :inner_ipv4, :outer_ipv4, :is_deleted], :unique=>true, :name => 'nw_vif_index'
    end
  end

  down do
    drop_table(:network_routes)
  end
end
