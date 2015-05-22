# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:host_nodes) do
      add_column :enabled, "tinyint(1)", :default=>true, :null=>false
    end
  end

  down do
    alter_table(:host_nodes) do
      drop_column :enabled
    end
  end
end
