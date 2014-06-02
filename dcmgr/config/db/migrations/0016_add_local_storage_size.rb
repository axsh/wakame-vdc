# encoding: utf-8

Sequel.migration do
  up do
    # storage size of the local stored volumes.
    alter_table(:host_nodes) do
      add_column :offering_disk_space_mb, 'int', :null=>false, :default=>0
    end
  end

  down do
  end
end

