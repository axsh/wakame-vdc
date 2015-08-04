# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:instances) do
      add_column :password_will_be_deleted_at, "datetime", :null=>true
    end
  end

  down do
    alter_table(:instances) do
      drop_column :password_will_be_deleted_at
    end
  end
end
