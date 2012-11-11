Sequel.migration do
  up do
    alter_table(:host_nodes) do
      # HostNode is no longer an account associated resource.
      drop_column :account_id
      rename_column :name, :display_name
    end

    alter_table(:storage_nodes) do
      # StorageNode is no longer an account associated resource.
      drop_column :account_id

      # make unit size clear.
      rename_column :offering_disk_space, :offering_disk_space_mb
      add_column :display_name, "varchar(255)", :null=>true
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
      #    securitygroup, l2overlay, passthrough
      add_column :network_mode, 'varchar(255)', :null=>false
      # physical_networks table has been renamed to dc_networks.
      rename_column :physical_network_id, :dc_network_id
      # Linux tc accepts floating point value as bandwidth.
      drop_column :bandwidth
      add_column :bandwidth, "float"
      add_column :ip_assignment, "varchar(255)", :default=>"asc", :null=>false

      # Permission flag for modification of the networks by users.
      add_column :editable, "tinyint(1)", :default=>false, :null=>false
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
      column :outgoing_port, "int(11)"

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

      add_column :account_id, "varchar(255)", :null=>false

      add_index [:account_id]
    end

    alter_table(:ip_leases) do
      set_column_type :ipv4, "int(11)", :unsigned=>true
      set_column_type :description, "varchar(255)"
      drop_column :instance_nic_id
      drop_column :alloc_type

      drop_index [:instance_nic_id, :network_id]
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
      add_column :is_cacheable, "tinyint(1)", :default=>false, :null=>false
      add_column :instance_model_name, "varchar(255)", :null=>false
      add_column :parent_image_id, "varchar(255)", :null=>true
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

      # Permission flag for the creation of new networks by
      # users.
      add_column :allow_new_networks, "tinyint(1)", :default=>false, :null=>false

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
      column :protocol, "varchar(255)", :null=>false
      column :port, "int(11)", :null=>false
      column :instance_protocol, "varchar(255)", :null=>false
      column :instance_port, "int(11)", :null=>false
      column :balance_algorithm, "varchar(255)", :null=>false
      column :cookie_name, "varchar(255)", :null=>true
      column :description, "text", :null=>true
      column :private_key, "text", :null=>true
      column :public_key, "text", :null=>true
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true
      column :display_name, "varchar(255)", :null=>true
      index [:uuid], :unique=>true, :name=>:uuid
      index [:account_id]
    end

    create_table(:load_balancer_targets) do
      primary_key :id, :type=>"int(11)"
      column :network_vif_id, "varchar(255)", :null=>false
      column :load_balancer_id, "int(11)", :null => false
      column :fallback_mode, "varchar(255)", :null=>false, :default => 'off'
      column :created_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true
      column :is_deleted, "int(11)", :null=>false
      index [:load_balancer_id, :network_vif_id, :is_deleted], :unique=>true,
             :name=>'load_balancer_targets_load_balancer_id_network_vif_id_index'
    end

    create_table(:network_vif_ip_leases) do
      primary_key :id, :type=>"int(11)"
      column :network_id, "int(11)", :null=>false
      column :network_vif_id, "int(11)", :null=>false
      column :ipv4, "int(11)", :null=>false, :unsigned=>true
      column :alloc_type, "int(11)", :default=>0, :null=>false
      column :description, "varchar(255)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :deleted_at, "datetime", :null=>true
      column :is_deleted, "int(11)", :null=>false
      index [:network_id, :network_vif_id, :ipv4, :is_deleted], :unique=>true,
             :name=>'network_vif_ip_leases_network_id_network_vif_id_ipv4_index'
      index [:updated_at]
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

    # # it is changed to represent the attributes for the bootable
    # # backup object. Any machine images have to be
    # # saved as backup object at first and then register nessecary
    # # additional information here.
    alter_table(:images) do
      add_column :backup_object_id, "varchar(255)"
      drop_column :source
      drop_column :md5sum
      #drop_column :boot_dev_type

      # Add missing deleted time column.
      add_column :deleted_at, "datetime"
    end

    create_table(:backup_objects) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :display_name, "varchar(255)", :null=>false
      column :service_type, "varchar(255)", :null=>false
      column :backup_storage_id, "int(11)", :null=>false
      column :size, "bigint", :null=>false
      column :allocation_size, "bigint", :null=>false
      column :container_format, "varchar(255)", :null=>false
      column :status, "int(11)", :default=>0, :null=>false
      column :state, "varchar(255)", :default=>"initialized", :null=>false
      column :object_key, "varchar(255)", :null=>false
      column :checksum, "varchar(255)", :null=>false
      column :description, "text"
      column :progress, "double", :null=>false, :default=>0.0
      column :deleted_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :purged_at, "datetime"

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
      column :display_name, "varchar(255)", :null=>false
      column :storage_type, "varchar(255)", :null=>false
      column :description, "text"
      column :base_uri, "varchar(255)", :null=>false
      column :deleted_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
    end

    alter_table(:volumes) do
      drop_column :snapshot_id
      add_column :backup_object_id, "varchar(255)"
      set_column_type :size, "bigint"
    end

    # Isono gem got new session_id column as of v0.2.12.
    alter_table(:job_states) do
      add_column :session_id, "varchar(80)", :null=>true
      add_column :job_name, "varchar(255)", :null=>true
      add_index [:session_id]
    end

    # move quota information to frontend.
    drop_table(:quotas)

    # remove instance_specs from dcmgr.
    alter_table(:instances) do
      add_column :hypervisor, "varchar(255)", :null=>false
      drop_column  :instance_spec_id
    end

    alter_table(:instances) do
      set_column_type :ssh_key_pair_id, "int(11)"
      set_column_allow_null :ssh_key_pair_id, false
      drop_column :ssh_key_data
    end

    alter_table(:dhcp_ranges) do
      set_column_type :range_begin, "int(11)", :unsigned=>true, :null=>false
      set_column_type :range_end, "int(11)", :unsigned=>true, :null=>false
      add_column :description, "varchar(255)"
    end

    alter_table(:accounts) do
      add_column :deleted_at, "datetime"
      add_column :purged_at, "datetime"
      add_index [:deleted_at]
    end

    alter_table(:tag_mappings) do
      add_column :sort_index, "int(11)", :null=>false, :default=>0
    end

    create_table(:mac_ranges) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false, :unique=>true
      column :vendor_id, "mediumint(8)", :unsigned=>true, :null=>false
      column :range_begin, "mediumint(8)", :unsigned=>true, :null=>false
      column :range_end, "mediumint(8)", :unsigned=>true, :null=>false
      column :description, "varchar(255)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
    end

    alter_table(:mac_leases) do
      set_column_type :mac_addr, "bigint", :unsigned=>true, :null=>false
    end

    create_table(:network_vif_monitors) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :network_vif_id, "int(11)", :null=>false
      column :enabled, "tinyint(1)", :default=>true, :null=>false
      column :protocol, "varchar(255)", :null=>false
      column :title, "varchar(255)", :null=>false
      column :params, "text", :null=>false
      column :deleted_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:deleted_at]
      index [:network_vif_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    # one to one association table for instances.
    create_table(:instance_monitor_attrs) do
      primary_key :id, :type=>"int(11)"
      column :instance_id, "int(11)", :null=>false
      column :mailaddr, "varchar(255)", :null=>false
      column :enabled, "tinyint(1)", :default=>false, :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:instance_id]
    end
  end

  down do
    drop_table(:host_node_vnets)
    drop_table(:network_services)
    drop_table(:mac_ranges)
    drop_table(:network_vif_monitors)
    drop_table(:instance_monitor_attrs)

    rename_table(:network_vifs, :instance_nics)

    alter_table(:host_nodes) do
      add_column :account_id, "varchar(255)", :null=>false
      rename_column :display_name, :name
    end

    alter_table(:storage_nodes) do
      add_column :account_id, "varchar(255)", :null=>false
      drop_column :display_name
    end

    alter_table(:images) do
      drop_column :file_format
      drop_column :root_device
      drop_column :is_cacheable
      drop_column :instance_model_name
    end

    alter_table(:vlan_leases) do
      drop_column :dc_network_id
      drop_index :tag_id
      add_index [:tag_id], :unique=>true
    end

    alter_table(:networks) do
      drop_column :gateway_network_id
      drop_column :ip_assignment
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

    alter_table(:job_states) do
      drop_column :session_id
      drop_index [:session_id]
    end

    alter_table(:job_states) do
      drop_column :command
    end

    alter_table(:volumes) do
      drop_column :backup_object_id
      add_column :snapshot_id, "varchar(255)"
    end

    # move quota information to frontend.
    create_table(:quotas) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "int(11)", :null=>false
      column :instance_total_weight, "double"
      column :volume_total_size, "int(11)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id], :unique=>true
    end

    # remove instance_specs from dcmgr.
    alter_table(:instances) do
      drop_column :hypervisor
      add_column :instance_spec_id, "int(11)", :null=>false
    end

    drop_table(:network_vif_ip_leases)

    alter_table(:ip_leases) do
      add_column :instance_nic_id, "int(11)", :null=>false
      add_column :alloc_type, "int(11)", :default=>0, :null=>false
      set_column_type :description, "text"

      add_index[:instance_nic_id, :network_id]
    end

    alter_table(:dhcp_ranges) do
      set_column_type :range_begin, "varchar(255)", :null=>false
      set_column_type :range_end, "varchar(255)", :null=>false
      drop_column :description
    end

    alter_table(:accounts) do
      drop_column :deleted_at
      drop_column :purged_at
    end

    alter_table(:tag_mappings) do
      drop_column :sort_index
    end

    alter_table(:mac_leases) do
      set_column_type :mac_addr, "char(12)", :null=>false
    end
  end
end
