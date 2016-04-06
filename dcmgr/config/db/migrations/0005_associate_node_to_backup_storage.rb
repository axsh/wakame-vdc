Sequel.migration do
  up do
    alter_table(:backup_storages) do
      # agent ID for backup service agent and VM.
      # null column to apply the node ID lazily and backup service
      # agent is optional configuration.
      add_column :node_id, "varchar(255)", :null=>true
    end
  end

  down do
    alter_table(:backup_storages) do
      drop_column :node_id
    end
  end
end

