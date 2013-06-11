Sequel.migration do
  up do
    alter_table(:network_vif_monitors) do
      drop_column :protocol
    end
  end

  down do
    drop_table(:network_vif_monitors) do
      add_column :protocol, "varchar(255)", :null=>false
    end
  end
end
  
