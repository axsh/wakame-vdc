Sequel.migration do
  up do
    alter_table(:host_nodes) do
      # HostNode is no longer an account associated resource.
      drop_column :account_id
    end

    alter_table(:storage_nodes) do
      # StorageNode is no longer an account associated resource.
      drop_column :account_id
    end
    
    create_table(:security_group_references) do
      primary_key :id, :type=>"int(11)"
      column :referencer_id, "int(11)", :null=>false
      column :referencee_id, "int(11)", :null=>false

      index [:referencer_id]
      index [:referencee_id]
    end

    alter_table(:networks) do
      add_column :gateway_network_id, "int(11)"
      # VLAN ID became a physical network attribute.
      drop_column :vlan_lease_id
      # link_interface(=bridge name) moved to hva.conf.
      # this is a physical device attribute associated to the host OS.
      drop_column :link_interface
      # mode name of network isolation/usage model:
      #    securitygroup, l2overlay, passthru
      add_column :network_mode, 'varchar(255)', :null=>false
      # physical_networks table has been renamed to dc_networks.
      rename_column :physical_network_id, :dc_network_id
      # Linux tc accepts floating point value as bandwidth.
      drop_column :bandwidth
      add_column :bandwidth, "float"
    end

    create_table(:host_node_vnets) do
      primary_key :id, :type=>"int(11)"
      column :host_node_id, "int(11)", :null=>false
      column :network_id, "int(11)", :null=>false
      column :broadcast_addr, "varchar(12)", :null=>false

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime"

      index [:host_node_id]
      index [:network_id]
      index [:broadcast_addr]
    end

    create_table(:network_services) do
      primary_key :id, :type=>"int(11)"
      column :network_vif_id, "int(11)"

      column :name, "varchar(255)", :null=>false
      column :incoming_port, "int(11)"
      column :outcoming_port, "int(11)"

      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:network_vif_id]
      index [:network_vif_id,:name], :unique=>true
    end
    
    create_table(:network_vif_security_groups) do
      primary_key :id, :type=>"int(11)"
      column :network_vif_id, "int(11)", :null=>false
      column :security_group_id, "int(11)", :null=>false

      index [:network_vif_id]
      index [:security_group_id]
    end

    drop_table(:security_group_rules)
    drop_table(:instance_security_groups)

    rename_table(:instance_nics, :network_vifs)

    alter_table(:network_vifs) do
      set_column_allow_null :instance_id, true
      set_column_allow_null :network_id, true

      add_column :network_service_id, "int(11)"
    end

    alter_table(:ip_leases) do
      rename_column :instance_nic_id, :network_vif_id

      drop_index [:instance_nic_id, :network_id]
      add_index [:network_vif_id, :network_id]
    end
    
    alter_table(:vlan_leases) do
      # The network underlaying this VLAN entry.
      add_column :dc_network_id, "int(11)", :null=>false
      # change uniqueness condition to combine physical network
      drop_index :tag_id
      add_index [:dc_network_id, :tag_id], :unique=>true
    end

    alter_table(:images) do
      add_column :file_format, "varchar(255)", :null=>false
      add_column :root_device, "varchar(255)"
    end

    rename_table(:physical_networks, :dc_networks)
    
    # DC network goes through customer traffic.
    alter_table(:dc_networks) do
      # physical interface name is described in hva.conf.
      drop_column :interface
      add_column :uuid, "varchar(255)", :null=>false
      add_column :vlan_lease_id, "int(11)"
      # Policy information
      # supported network mode list
      add_column :offering_network_modes, "text", :null=>false

      add_index [:uuid], :unique=>true, :name=>:uuid
    end
		
    create_table(:accounting_logs) do
      primary_key :id, :type=>"int(11)"
			column :uuid, "varchar(255)", :null=>false
      column :account_id, "varchar(255)", :null=>false
			column :resource_type, "varchar(255)", :null=>false
      column :event_type, "varchar(255)", :null=>false
			column :vchar_value, "varchar(255)", :null=>true
			column :int_value, "bigint(20)", :null=>true
      column :blob_value, "blob", :null=>true
      column :created_at, "datetime", :null=>false

			index [:uuid], :name=>:uuid
      index [:account_id]
      index [:resource_type]
      index [:event_type]
      index [:created_at]
    end

    create_table(:load_balancers) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :account_id, "varchar(255)", :null=>false
      column :instance_id, "int(11)", :null=>false
      column :protocol, "varchar(4)", :null=>false
      column :port, "int(11)", :null=>false
      column :instance_protocol, "varchar(4)", :null=>false
      column :instance_port, "int(11)", :null=>false
      column :balance_name, "varchar(255)", :null=>false
      column :cookie_name, "varchar)255)", :null=>true
      column :description, "text", :null=>true
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false  
      column :deleted_at, "datetime", :null=>true
      index [:uuid], :name=>:uuid
      index [:account_id]
    end
    
    create_table(:load_balancer_targets) do
      primary_key :id, :type=>"int(11)"
      column :network_vif_uuid, "varchar(255)", :null=>false
      column :load_balancer_id, "int(11)"
      column :created_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true
      index [:load_balancer_id, :network_vif_id], :unique=>true
    end

    # Add service_type column for service type resources
    alter_table(:instances) do
      add_column :service_type, "varchar(255)", :null=>false
    end
    alter_table(:volumes) do
      add_column :service_type, "varchar(255)", :null=>false
    end
    alter_table(:volume_snapshots) do
      add_column :service_type, "varchar(255)", :null=>false
    end
    alter_table(:security_groups) do
      add_column :service_type, "varchar(255)", :null=>false
    end
    alter_table(:images) do
      add_column :service_type, "varchar(255)", :null=>false
    end
    alter_table(:networks) do
      add_column :service_type, "varchar(255)", :null=>false
    end
    alter_table(:ssh_key_pairs) do
      add_column :service_type, "varchar(255)", :null=>false
    end

<<<<<<< HEAD
    # Add display_name column
    alter_table(:instances) do
      add_column :display_name, "varchar(255)", :null=>false
    end
    alter_table(:volumes) do
      add_column :display_name, "varchar(255)", :null=>false
    end
    alter_table(:volume_snapshots) do
      add_column :display_name, "varchar(255)", :null=>false
    end
    alter_table(:security_groups) do
      add_column :display_name, "varchar(255)", :null=>false
    end
    alter_table(:images) do
      add_column :display_name, "varchar(255)", :null=>false
    end
    alter_table(:networks) do
      add_column :display_name, "varchar(255)", :null=>false
    end
    alter_table(:ssh_key_pairs) do
      add_column :display_name, "varchar(255)", :null=>false
    end
=======
    # # it is changed to represent the attributes for the bootable
    # # backup object. Any machine images have to be 
    # # saved as backup object at first and then register nessecary
    # # additional information here.
    # alter_table(:images) do
    #   add_column :backup_object_id, "varchar(255)", :null=>false
    #   drop_column :source
    #   drop_column :md5sum
    #   drop_column :boot_dev_type
    # end
    
    create_table(:backup_objects) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :service_type, "varchar(255)", :null=>false
      column :backup_storage_id, "int(11)", :null=>false
      column :size, "bigint", :null=>false
      column :status, "int(11)", :default=>0, :null=>false
      column :state, "varchar(255)", :default=>"initialized", :null=>false
      column :object_key, "varchar(255)", :null=>false
      column :checksum, "varchar(255)", :null=>false
      column :description, "text"
      column :deleted_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      
      index [:uuid], :unique=>true, :name=>:uuid
      index [:account_id]
      index [:deleted_at]
      index [:backup_storage_id]
    end

    # rename_table(:volume_snapshots, :backup_objects)
    
    # Object storage stores backup objects.
    create_table(:backup_storages) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :storage_type, "varchar(255)", :null=>false
      column :description, "text"
      column :base_uri, "varchar(255)", :null=>false
      column :deleted_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
    end
  end
  
  down do
    drop_table(:host_node_vnets)
    drop_table(:network_services)

    rename_table(:network_vifs, :instance_nics)

    alter_table(:host_nodes) do
      add_column :account_id, "varchar(255)", :null=>false
    end

    alter_table(:storage_nodes) do
      add_column :account_id, "varchar(255)", :null=>false
    end

    alter_table(:images) do
      drop_column :file_format
      drop_column :root_device
    end

    alter_table(:vlan_leases) do
      drop_column :dc_network_id
      drop_index :tag_id
      add_index [:tag_id], :unique=>true
    end
    
    alter_table(:networks) do
      drop_column :gateway_network_id
      add_column :vlan_lease_id, "int(11)", :default=>0, :null=>false
      add_column :link_interface, "varchar(255)", :null=>false
    end

    rename_table(:dc_networks, :physical_networks)

    alter_table(:physical_networks) do
      add_column :interface, "varchar(255)"
      drop_column :bridge
      drop_column :bridge_type
    end

    alter_table(:instances) do
      drop_column :service_type
    end
    alter_table(:volumes) do
      drop_column :service_type
    end
    alter_table(:volume_snapshots) do
      drop_column :service_type
    end
    alter_table(:security_groups) do
      drop_column :service_type
    end
    alter_table(:images) do
      drop_column :service_type
    end
    alter_table(:networks) do
      drop_column :service_type
    end
    alter_table(:ssh_key_pairs) do
      drop_column :service_type
    end

    # Delete display_name column
    alter_table(:instances) do
      drop_column :display_name
    end
    alter_table(:volumes) do
      drop_column :display_name
    end
    alter_table(:volume_snapshots) do
      drop_column :display_name
    end
    alter_table(:security_groups) do
      drop_column :display_name
    end
    alter_table(:images) do
      drop_column :display_name
    end
    alter_table(:networks) do
      drop_column :display_name
    end
    alter_table(:ssh_key_pairs) do
      drop_column :display_name
    end
    drop_table(:backup_storages)
  end
end
