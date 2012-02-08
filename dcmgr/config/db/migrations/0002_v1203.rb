Sequel.migration do
  up do

    # images table is changed to represent the missing attributes for
    # the bootable backup object. Any machine images have to be saved
    # as backup object item and 
    alter_table(:images) do
      drop_column :boot_dev_type
      drop_column :source
      drop_column :md5sum
      add_column :backup_object_id, "varchar(255)", :null=>false
    end
    
    # Instance template is no longer deal with Dcmgr since the
    # instance API is changed to import/export the JSON document that
    # describes detail instance specification.
    drop_table(:instance_specs)

    alter_table(:instances) do
      # Add columns have refered to the instance_specs table.
      add_column :hypervisor, "varchar(255)", :null=>false
      add_column :arch, "varchar(255)", :null=>false

      # The table association model is weak for keeping histories of
      # change what items were added/removed and when. Therefore, the
      # using table association is going to be stopped.
      
      # Remove the association to the images table. The Image model
      # becomes just a template data source to create an instance.
      add_column :image_data, "text"
      # TODO: import original data in images table to image_data column.
      drop_column :image_id
      drop_column :ssh_key_pair_id
      
      # vNIC and Volume, they are represented as reference resource
      # from the instance using one to many table association.
      #
      # The table associations to those tables are kept as before but
      # they also need to save the associated ID snapshot to the
      # blob columns. It allows to track these devices when they
      # were installed/uninstalled.
      #
      # Don't need to put entire dataset of each item. Because the
      # their attribute change hisotry, i.e. volume size or mac
      # address, is segregated event from the instance attribute.
      add_column :vnic_ids, "text"
      add_column :volume_ids, "text"

      # Volume ID can be used as the OS boot drive.
      add_column :boot_volume_id, "varchar(255)", :null=>false
    end

    alter_table(:volume_snapshots) do
      drop_column :storage_node_id

      add_column :backup_storage_id, "varchar(255)"
      #rename_column :destination_key, :path

      add_column :chksum, "varchar(255)", :null=>false
      add_column :progress, "int(11)", :default=>0, :null=>false
      add_column :description, "text"
    end
    
    rename_table(:volume_snapshots, :backup_objects)
    
    # Storage address for backup objects.
    create_table(:backup_storages) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :storage_type, "varchar(255)", :null=>false
      column :description, "text"
      column :base_uri, "varchar(255)", :null=>false
      column :deleted_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
    end
    
    alter_table(:volumes) do
      # boot device flag has been moved to instances table as boot_volume_id.
      drop_column :boot_dev
      # Rname snapshot_id to backup_object_id. since the backup
      # object is introduced as replacement of volume snapshot in
      # this version, the UUID prefix is changed from snap- to bkup-.
      drop_column :snapshot_id

      add_column :backup_object_id, "varchar(255)"
      
      add_column :device_index, "int(11)", :null=>false
      add_column :progress, "int(11)", :default=>0, :null=>false
      add_column :description, "text"
      add_column :read_only, "int(11)", :default=>0, :null=>false
    end

    alter_table(:host_nodes) do
      add_column :deleted_at, "datetime"

      add_index :deleted_at
    end

    alter_table(:storage_nodes) do
      add_column :deleted_at, "datetime"

      add_index :deleted_at
    end
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


    rename_table(:backup_objects, :volume_snapshots)

    drop_table(:backup_storages)
  end
end
