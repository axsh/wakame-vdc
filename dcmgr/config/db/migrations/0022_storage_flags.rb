# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:storage_nodes) do
      add_column :scheduling_enabled, "tinyint(1)", :default=>true, :null=>false
    end
  end
end
