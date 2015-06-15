Sequel.migration do
  up do
    create_table(:load_balancer_inbounds) do
      primary_key :id, :type=>"int(11)"
      column :load_balancer_id, "int(11)", :null => false
      column :protocol, "varchar(255)", :null=>false
      column :port, "int(11)", :null=>false
      column :created_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true
      column :is_deleted, "int(11)", :null=>false
      index [:load_balancer_id]
    end

    alter_table(:load_balancers) do
      drop_column :port
      drop_column :protocol
    end

  end

  down do
    drop_table(:load_balancer_inbounds)

    alter_table(:load_balancers) do
      add_column :port, "int(11)", :null=>false
      add_column :protocol, "varchar(255)", :null=>false
    end
  end
end
