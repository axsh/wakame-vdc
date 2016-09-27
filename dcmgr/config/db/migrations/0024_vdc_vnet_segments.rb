
Sequel.migration do

  up do
    alter_table(:networks) do
      add_column :segment_uuid, "varchar(255)"
    end
  end

  down do
    alter_table(:networks) do
      drop_column :segment_uuid
    end
  end
end
