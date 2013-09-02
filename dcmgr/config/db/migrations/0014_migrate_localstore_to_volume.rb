# encoding: utf-8

require 'dcmgr'
require 'dcmgr/models/base_new'

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
      column :instance_id, "int(11)", :null=>false
      column :mount_label, "varchar(255)", :null=>false
      column :path, "varchar(255)", :null=>false

      index [:instance_id]
    end

    create_table(:iscsi_volumes) do
      primary_key :id, :type=>"int(11)"
      column :iscsi_storage_node_id, "int(11)", :null=>true
      column :iqn, "varchar(255)", :null=>true
      column :lun, "varchar(255)", :null=>true
      column :path, "varchar(255)", :null=>false

      index [:iqn, :lun], :unique=>true
    end

    create_table(:iscsi_storage_nodes) do
      primary_key :id, :type=>"int(11)"
      column :ip_address, "varchar(255)", :null=>false
    end

    MigrateLocalStoreToVolume.data_migrate

    alter_table(:volumes) do
      drop_column :boot_dev
      drop_column :storage_node_id
      drop_column :host_device_name
      drop_column :transport_information
      drop_column :export_path
    end

    alter_table(:storage_nodes) do
      drop_column :ipaddr
      drop_column :transport_type
    end
  end

  module MigrateLocalStoreToVolume
    def self.data_migrate
      db = Sequel::DATABASES.first
      db[:instances].filter(:state=>['running', 'halted']).each { |instance|
        image = db[:images][:id=>instance[:image_id]]
				case image[:boot_dev_type]
				when Dcmgr::Constants::Image::BOOT_DEV_LOCAL

          backup_object = db[:backup_objects][:uuid=>image[:backup_object_id].sub(/^bo-/,'')]

          vol_uuid = Dcmgr::Models::Taggable.generate_uuid
          db[:volumes].insert(:uuid=>vol_uuid,
                              :account_id=>instance[:account_id],
                              :status=>'online',
                              :state => Dcmgr::Constants::Volume::STATE_ATTACHED,
                              :size  => backup_object[:size],
                              :guest_device_name => boot_device_name(instance[:hypervisor]),
                              :request_params => '--- {}',
                              :deleted_at => nil,
                              :attached_at => instance[:updated_at],
                              :detached_at => nil,
                              :created_at => instance[:created_at],
                              :updated_at => instance[:updated_at],
                              :service_type => instance[:service_type],
                              :backup_object_id => "bo-#{backup_object[:uuid]}",
                              :volume_type => 'Dcmgr::Models::LocalVolume',
                              )
          new_volume = db[:volumes][:uuid=>vol_uuid]

          db[:local_volumes].insert(:id   => new_volume[:id],
                                    # old instances store the boot image as "{vm_data_dir}/i-xxxxx/i-xxxxx".
                                    :path => "i-#{instance[:uuid]}",
                                    :mount_label => 'instance',
                                    :instance_id => instance[:id],
                                    )
          db[:instances].filter(:id=>instance[:id]).update(:boot_volume_id=>"vol-#{new_volume[:uuid]}")
        when Dcmgr::Constants::Image::BOOT_DEV_SAN

          db[:volumes].filter(:state=>'attached', :instance_id=>instance[:id]).each { |volume|
            db[:volumes].filter(:id=>volume[:id]).update(:volume_type=>'Dcmgr::Models::IscsiVolume')
            if volume[:boot_dev] == 1
              db[:instances].filter(:id=>instance[:id]).update(:boot_volume_id=>"vol-#{volume[:uuid]}")
            end
          
            trans_info = YAML.load(volume[:transport_information])
            db[:iscsi_volumes].insert(:id=>volume[:id],
                                      :sotrage_node_id => volume[:storage_node_id],
                                      :iqn => trans_info[:iqn],
                                      :lun => trans_info[:lun],
                                      :path => volume[:export_path],
                                      )
          }
				end
      }
    end

    def self.boot_device_name(hypervisor)
      case hypervisor.to_s
      when 'kvm'
        'vda'
      when 'openvz', 'lxc'
        '/'
      else
        raise "Unsupported hypervisor: #{hypervisor}"
      end
    end
  end
end

