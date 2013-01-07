Sequel.migration do
  up do
    create_table(:text_logs) do
      primary_key :id, :type=>"int(11)"
      column :resource_type, "varchar(255)", :null=>false
      column :payload, "varchar(255)", :null=>false
      column :created_at, "decimal(16,6)", :null=>false
      index [:created_at]
    end
  end

  down do
    drop_table(:text_logs)
  end
end
