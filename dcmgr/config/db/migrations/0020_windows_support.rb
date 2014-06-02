# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:images) do
      add_column :os_type, "varchar(255)", null: false, default: "linux"
    end

    alter_table(:instances) do
      add_column :encrypted_password, "varchar(255)"
    end
  end

  down do
    alter_table(:images) do
      drop_column :os_type
    end

    alter_table(:instances) do
      drop_column :encrypted_password
    end
  end
end
