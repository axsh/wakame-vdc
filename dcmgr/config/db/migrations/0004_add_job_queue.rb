Sequel.migration do
  up do
    create_table(:queued_jobs) do
      primary_key :id, :type=>"int(11)"
      column :parent_id, "int(11)", :null=>true
      column :uuid, "varchar(255)", :null=>false
      column :queue_name, "varchar(255)", :null=>false
      column :params, "text", :null=>false
      column :resource_id, "varchar(255)", :null=>false
      column :worker_id, "varchar(255)", :null=>true
      column :state, "varchar(255)", :null=>false
      column :retry_max, "int(11)", :null=>false
      column :retry_count, "int(11)", :null=>false
      column :finish_status, "varchar(255)", :null=>true
      column :failure_reason, "varchar(255)", :null=>true
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :finished_at, "datetime", :null=>true
      column :started_at, "datetime", :null=>true

      index [:queue_name, :state, :worker_id]
      index [:resource_id, :started_at]
      index [:uuid], :unique=>true, :name=>:uuid
    end
  end

  down do
    drop_table(:queued_jobs)
  end
end
  
