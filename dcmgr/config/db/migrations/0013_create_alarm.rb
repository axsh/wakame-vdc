Sequel.migration do
  up do
    create_table(:alarms) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :account_id, "varchar(255)", :null=>false
      column :resource_id, "varchar(255)", :null=>false
      column :display_name, "varchar(255)", :null=>true
      column :metric_name, "varchar(255)", :null=>false
      column :description, "text", :null=>true
      column :params, "text", :null=>false
      column :enable, "tinyint(1)", :null=>false, :default=> 1, :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true
    end
  end

  down do
    drop_table(:alarms)
  end
end