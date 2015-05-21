# encoding: utf-8

Sequel.migration do
  up do
    create_table(:nfs_storage_nodes) do
      primary_key :id, :type=>"int(11)"
      column :mount_point, "varchar(255)", :null=>false
    end
    create_table(:nfs_volumes) do
      primary_key :id, :type=>"int(11)"
      column :nfs_storage_node_id, "int(11)", :null=>false
      column :path, "varchar(255)", :null=>false

      index [:nfs_storage_node_id]
    end
  end

  down do
    drop_table(:nfs_storage_nodes)
    drop_table(:nfs_volumes)
  end
end

