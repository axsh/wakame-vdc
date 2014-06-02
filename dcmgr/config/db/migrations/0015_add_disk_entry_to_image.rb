# encoding: utf-8

Sequel.migration do
  up do
    # Disk information.
    alter_table(:images) do
      add_column :volumes, "text", :null=>false
      add_column :vifs, "text", :null=>false
    end

    alter_table(:backup_objects) do
      # source volume to take backup from.
      add_column :source_volume_id, "varchar(255)", :null=>false
    end

    # TODO: fill backup_objects.source_volume_id column?
  end

  down do
  end
end

