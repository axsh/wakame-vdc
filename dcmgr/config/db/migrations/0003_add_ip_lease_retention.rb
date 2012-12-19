#Todo: Rename this migration file to 0004 when merging with public master
Sequel.migration do
  up do
    alter_table(:networks) do
      add_column :retention_seconds, "int(11)", :default=>0, :null=>false
    end
  end

  down do
    alter_table(:networks) do
      drop_column :retention_seconds
    end
  end
end
