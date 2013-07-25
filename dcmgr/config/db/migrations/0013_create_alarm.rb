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
      column :evaluation_periods, "integer", :null=>false
      column :params, "text", :null=>false
      column :enabled, "tinyint(1)", :null=>false, :default=> 1, :null=>false
      column :state, "varchar(255)", :null=>false, :null=>false
      column :state_timestamp, "datetime", :null=>false
      column :ok_actions, "text", :null=>true
      column :alarm_actions, "text", :null=>true
      column :insufficient_data_actions, "text", :null=>true
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true
    end
  end

  down do
    drop_table(:alarms)
  end
end
