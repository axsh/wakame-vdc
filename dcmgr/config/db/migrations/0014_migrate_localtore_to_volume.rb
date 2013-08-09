# encoding: utf-8

Sequel.migration do
  up do
    # Volume and StorageNode are Class Table Inheritance models.
    alter_table(:instances) do
      # Allow NULL because volume type can be determined later.
      add_column :boot_volume_id, "varchar(255)", :null=>false
    end

    alter_table(:volumes) do
      # Allow NULL because volume type can be determined later.
      add_column :volume_type, "varchar(255)", :null=>true
    end

    create_table(:local_volumes) do
      primary_key :id, :type=>"int(11)"
      column :host_node_id, "int(11)", :null=>true
      column :mount_label, "varchar(255)", :null=>false
      column :path, "varchar(255)", :null=>false
    end

    create_table(:iscsi_volumes) do
      primary_key :id, :type=>"int(11)"
      column :iscsi_storage_node_id, "int(11)", :null=>true
      column :iqn, "varchar(255)", :null=>true
      column :lun, "varchar(255)", :null=>true

      index [:iqn, :lun], :unique=>true
    end

    create_table(:iscsi_storage_nodes) do
      primary_key :id, :type=>"int(11)"
      column :ip_address, "varchar(255)", :null=>false
    end

    # TODO: Data migration before drop columns.

    alter_table(:volumes) do
      drop_column :storage_node_id
      drop_column :transport_information
    end

    alter_table(:storage_nodes) do
      drop_column :ipaddr
      drop_column :transport_type
    end
  end

  down do
  end
end
  
