Sequel.migration do
  up do
    create_table(:accounts) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :description, "varchar(255)"
      column :enabled, "int(11)", :default=>1, :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:frontend_systems) do
      primary_key :id, :type=>"int(11)"
      column :kind, "varchar(255)", :null=>false
      column :key, "varchar(255)", :null=>false
      column :credential, "varchar(255)"

      index [:key], :unique=>true, :name=>:key
    end

    create_table(:histories) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :attr, "varchar(255)", :null=>false
      column :vchar_value, "varchar(255)"
      column :blob_value, "text"
      column :created_at, "datetime", :null=>false

      index [:uuid, :attr]
      index [:uuid, :created_at]
    end

    create_table(:host_nodes) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :node_id, "varchar(255)"
      column :arch, "varchar(255)", :null=>false
      column :hypervisor, "varchar(255)", :null=>false
      column :name, "varchar(255)", :null => true
      column :offering_cpu_cores, "int(11)", :null=>false
      column :offering_memory_size, "int(11)", :null=>false

      index [:account_id]
      index [:node_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:hostname_leases) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :hostname, "varchar(32)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id, :hostname], :unique=>true
    end

    create_table(:images) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :boot_dev_type, "int(11)", :default=>1, :null=>false
      column :source, "text", :null=>false
      column :arch, "varchar(255)", :null=>false
      column :description, "text"
      column :md5sum, "varchar(255)", :null=>false
      column :is_public, "tinyint(1)", :null=>false, :default=>false
      column :state, "varchar(255)", :default=>"init", :null=>false
      column :features, "text"

      index [:account_id]
      index [:is_public]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:instance_security_groups) do
      primary_key :id, :type=>"int(11)"
      column :instance_id, "int(11)", :null=>false
      column :security_group_id, "int(11)", :null=>false

      index [:instance_id]
      index [:security_group_id]
    end

    create_table(:instance_nics) do
      primary_key :id, :type=>"int(11)"
      column :uuid, "varchar(255)", :null=>false
      column :instance_id, "int(11)", :null=>false
      column :network_id, "int(11)", :null=>false
      column :nat_network_id, "int(11)"
      column :mac_addr, "varchar(12)", :null=>false
      column :device_index, "int(11)", :null=>false
      column :deleted_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:deleted_at]
      index [:instance_id]
      index [:mac_addr]
      index [:uuid], :unique=>true, :name=>:uuid
    end

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

    create_table(:instances) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :host_node_id, "int(11)"
      column :image_id, "int(11)", :null=>false
      column :instance_spec_id, "int(11)", :null=>false
      column :state, "varchar(255)", :default=>"init", :null=>false
      column :status, "varchar(255)", :default=>"init", :null=>false
      column :hostname, "varchar(32)", :null=>false
      column :ssh_key_pair_id, "varchar(255)"
      column :ha_enabled, "int(11)", :default=>0, :null=>false
      column :quota_weight, "double", :default=>0.0, :null=>false
      column :cpu_cores, "int(11)", :null=>false
      column :memory_size, "int(11)", :null=>false
      column :user_data, "text", :null=>false
      column :runtime_config, "text", :null=>false
      column :ssh_key_data, "text"
      column :request_params, "text", :null=>false
      column :terminated_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id]
      index [:host_node_id]
      index [:state]
      index [:terminated_at]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:ip_leases) do
      primary_key :id, :type=>"int(11)"
      column :instance_nic_id, "int(11)"
      column :network_id, "int(11)", :null=>false
      column :ipv4, "varchar(50)"
      column :alloc_type, "int(11)", :default=>0, :null=>false
      column :description, "text"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:instance_nic_id, :network_id]
      index [:network_id, :ipv4], :unique=>true
    end

    create_table(:job_states) do
      primary_key :id, :type=>"int(11)"
      column :job_id, "varchar(80)", :null=>false
      column :parent_job_id, "varchar(80)"
      column :node_id, "varchar(255)", :null=>false
      column :state, "varchar(255)", :null=>false
      column :message, "text", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :started_at, "datetime"
      column :finished_at, "datetime"

      index [:job_id], :unique=>true
    end

    create_table(:mac_leases) do
      primary_key :id, :type=>"int(11)"
      column :mac_addr, "char(12)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:mac_addr], :unique=>true
    end

    create_table(:security_groups) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :description, "varchar(255)"
      column :rule, "text"

      index [:account_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:security_group_rules) do
      primary_key :id, :type=>"int(11)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :security_group_id, "int(11)", :null=>false
      column :permission, "varchar(255)", :null=>false

      index [:security_group_id]
    end

    create_table(:networks) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :ipv4_network, "varchar(255)", :null=>false
      column :ipv4_gw, "varchar(255)"
      column :prefix, "int(11)", :default=>24, :null=>false
      column :metric, "int(11)", :default=>100, :null=>false
      column :domain_name, "varchar(255)"
      column :dns_server, "varchar(255)"
      column :dhcp_server, "varchar(255)"
      column :metadata_server, "varchar(255)"
      column :metadata_server_port, "int(11)"
      column :bandwidth, "int(11)"
      column :vlan_lease_id, "int(11)", :default=>0, :null=>false
      column :nat_network_id, "int(11)"
      column :physical_network_id, "int(11)"
      column :link_interface, "varchar(255)", :null=>false
      column :description, "text"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id]
      index [:nat_network_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:dhcp_ranges) do
      primary_key :id, :type=>"int(11)"
      column :network_id, "int(11)", :null=>false
      column :range_begin, "varchar(255)", :null=>false
      column :range_end, "varchar(255)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      index [:network_id]
    end

    create_table(:physical_networks) do
      primary_key :id, :type=>"int(11)"
      column :name, "varchar(255)", :null=>false
      column :interface, "varchar(255)"
      column :description, "text"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      index [:name], :unique=>true
    end

    create_table(:node_states) do
      primary_key :id, :type=>"int(11)"
      column :node_id, "varchar(80)", :null=>false
      column :boot_token, "varchar(10)", :null=>false
      column :state, "varchar(10)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :last_ping_at, "datetime", :null=>false

      index [:node_id], :unique=>true
    end

    create_table(:quotas) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "int(11)", :null=>false
      column :instance_total_weight, "double"
      column :volume_total_size, "int(11)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id], :unique=>true
    end

    create_table(:request_logs) do
      primary_key :id, :type=>"int(11)"
      column :request_id, "varchar(40)", :null=>false
      column :frontend_system_id, "varchar(40)", :null=>false
      column :account_id, "varchar(40)", :null=>false
      column :requester_token, "varchar(255)"
      column :request_method, "varchar(10)", :null=>false
      column :api_path, "varchar(255)", :null=>false
      column :params, "text", :null=>false
      column :response_status, "int(11)", :null=>false
      column :response_msg, "text"
      column :requested_at, "datetime", :null=>false
      column :requested_at_usec, "int(11)", :null=>false
      column :responded_at, "datetime", :null=>false
      column :responded_at_usec, "int(11)", :null=>false

      index [:request_id], :unique=>true, :name=>:request_id
    end

    create_table(:ssh_key_pairs) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "char(8)", :null=>false
      column :finger_print, "varchar(100)", :null=>false
      column :public_key, "text", :null=>false
      column :private_key, "text"
      column :description, "text"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:storage_nodes) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :node_id, "varchar(255)", :null=>false
      column :export_path, "varchar(255)", :null=>false
      column :offering_disk_space, "int(11)", :null=>false
      column :transport_type, "varchar(255)", :null=>false
      column :storage_type, "varchar(255)", :null=>false
      column :ipaddr, "varchar(255)", :null=>false
      column :snapshot_base_path, "varchar(255)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id]
      index [:node_id]
      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:tag_mappings) do
      primary_key :id, :type=>"int(11)"
      column :tag_id, "int(11)", :null=>false
      column :uuid, "varchar(255)", :null=>false

      index [:tag_id]
      index [:uuid]
    end

    create_table(:tags) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :type_id, "int(11)", :null=>false
      column :name, "varchar(255)", :null=>false
      column :attributes, "varchar(255)"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:account_id]
      index [:account_id, :type_id, :name], :unique=>true
      index [:uuid], :unique=>true, :name=>:uuid
    end

    create_table(:vlan_leases) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :tag_id, "int(11)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:uuid], :unique=>true, :name=>:uuid
      index [:account_id]
      index [:tag_id], :unique=>true
    end

    create_table(:volume_snapshots) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :storage_node_id, "int(11)", :null=>false
      column :origin_volume_id, "varchar(255)", :null=>false
      column :size, "int(11)", :null=>false
      column :status, "int(11)", :default=>0, :null=>false
      column :state, "varchar(255)", :default=>"initialized", :null=>false
      column :destination_key, "varchar(255)", :null=>false
      column :deleted_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:uuid], :unique=>true, :name=>:uuid
      index [:account_id]
      index [:deleted_at]
      index [:storage_node_id]
    end

    create_table(:volumes) do
      primary_key :id, :type=>"int(11)"
      column :account_id, "varchar(255)", :null=>false
      column :uuid, "varchar(255)", :null=>false
      column :storage_node_id, "int(11)"
      column :status, "varchar(255)", :default=>"initialized", :null=>false
      column :state, "varchar(255)", :default=>"initialized", :null=>false
      column :size, "int(11)", :null=>false
      column :instance_id, "int(11)"
      column :boot_dev, "int(11)", :default=>0, :null=>false
      column :snapshot_id, "varchar(255)"
      column :host_device_name, "varchar(255)"
      column :guest_device_name, "varchar(255)"
      column :export_path, "varchar(255)", :null=>false
      column :transport_information, "text"
      column :request_params, "text", :null=>false
      column :deleted_at, "datetime"
      column :attached_at, "datetime"
      column :detached_at, "datetime"
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false

      index [:uuid], :unique=>true, :name=>:uuid
      index [:account_id]
      index [:deleted_at]
      index [:instance_id]
      index [:snapshot_id]
      index [:storage_node_id]
    end

    self[:accounts].insert(:id=>100, :uuid=>'00000000', :description=>'datacenter system account', :updated_at=>Time.now, :created_at=>Time.now)
    self[:accounts].insert(:id=>101, :uuid=>'shpoolxx', :description=>'system account for shared resources', :updated_at=>Time.now, :created_at=>Time.now)
    self[:quotas].insert(:id=>1, :account_id=>100,
                         :instance_total_weight=>1000000, :volume_total_size=>9999999,
                         :updated_at=>Time.now, :created_at=>Time.now)
    self[:quotas].insert(:id=>2, :account_id=>101,
                         :instance_total_weight=>1000000, :volume_total_size=>9999999,
                         :updated_at=>Time.now, :created_at=>Time.now)
    self[:tags].insert(:id=>1, :uuid=>'shhost', :account_id=>'a-shpoolxx', :type_id=>11, :name=>"default_shared_hosts", :updated_at=>Time.now, :created_at=>Time.now)
    self[:tags].insert(:id=>2, :uuid=>'shnet', :account_id=>'a-shpoolxx', :type_id=>10,:name=>"default_shared_networks", :updated_at=>Time.now, :created_at=>Time.now)
    self[:tags].insert(:id=>3, :uuid=>'shstor', :account_id=>'a-shpoolxx', :type_id=>12, :name=>"default_shared_storage", :updated_at=>Time.now, :created_at=>Time.now)
  end

  down do
    drop_table(:accounts, :frontend_systems, :histories, :host_nodes, :hostname_leases, :images, :instance_security_groups, :instance_nics, :instance_specs, :instances, :ip_leases, :job_states, :mac_leases, :security_groups, :security_group_rules, :networks, :node_states, :quotas, :request_logs, :ssh_key_pairs, :storage_nodes, :tag_mappings, :tags, :vlan_leases, :volume_snapshots, :volumes, :dhcp_ranges, :physical_networks)
  end
end
