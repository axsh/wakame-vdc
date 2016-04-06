# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:host_nodes) do
      rename_column :enabled, :scheduling_enabled
    end
  end

  down do
    alter_table(:host_nodes) do
      rename_column :scheduling_enabled, :enabled
    end
  end
end
