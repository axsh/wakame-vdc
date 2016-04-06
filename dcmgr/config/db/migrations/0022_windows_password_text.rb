# encoding: utf-8

Sequel.migration do
  up do
    alter_table(:instances) do
      set_column_type :encrypted_password, "text"
    end
  end

  down do
    alter_table(:instances) do
      set_column_type :encrypted_password, "varchar(255)"
    end
  end
end
