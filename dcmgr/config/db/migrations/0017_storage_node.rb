# encoding: utf-8

Sequel.migration do
  up do
    # they have moved to sta.conf
    alter_table(:storage_nodes) do
      drop_column :export_path
      drop_column :snapshot_base_path
    end
  end

  down do
    alter_table(:storage_nodes) do
      add_column :export_path, "varchar(255)", :null=>false
      add_column :snapshot_base_path, "varchar(255)", :null=>false
    end
  end
end
