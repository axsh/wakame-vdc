# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:images) do
      add_column :os_type, "varchar(255)", null: false, default: "generic"
    end
  end

  down do
    alter_table(:images) do
      drop_column :os_type
    end
  end
end
