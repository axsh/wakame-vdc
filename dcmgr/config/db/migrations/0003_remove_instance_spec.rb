Sequel.migration do
  up do
    drop_table(:instance_specs)
  end

  down do
    create_table(:instance_specs) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :hypervisor, "varchar(255)", :null=>false
      column :arch, "varchar(255)", :null=>false
      column :cpu_cores, "int(11)", :null=>false
      column :memory_size, "int(11)", :null=>false
      column :quota_weight, "double", :default=>1.0, :null=>false
      column :vifs, "text", :default=>''
      column :drives, "text", :default=>''
      column :config, "text", :null=>false, :default=>''
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end
  end
end
  
