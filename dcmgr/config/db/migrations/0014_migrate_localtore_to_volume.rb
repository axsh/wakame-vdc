# encoding: utf-8

require 'dcmgr'

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
    DataMigration.migrate

    alter_table(:volumes) do
      drop_column :boot_dev
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

  module DataMigration
    include Dcmgr::Models
    
    def self.migrate
      # add volumes for running instance with local store instance.
      Instance.dataset.runnings.each { |instance|
        next if instance.image.boot_dev_type != Dcmgr::Constants::Image::BOOT_DEV_LOCAL
        
        boot_vol = instance.image.backup_object.create_volume(instance.account) do |v|
          v.state = Dcmgr::Constants::Volume::STATE_ATTACHED
        end
        boot_vol.save
        if instance.image.boot_dev_type == Dcmgr::Constants::Image::BOOT_DEV_LOCAL
          instance.add_local_volume(boot_vol).tap { |v|
            v.volume_device.tap { |vd|
              # old instances store the boot image as "{vm_data_dir}/i-xxxxx/i-xxxxx".
              vd.path = instance.canonical_uuid
              vd.mount_label = 'instance'
              vd.instance_id = instance.pk
              vd.save_changes
            }
          }
        end
        
        instance.boot_volume_id = boot_vol.canonical_uuid
        instance.save_changes
      }
      
      Instance.dataset.runnings.each { |instance|
        next if instance.image.boot_dev_type != Dcmgr::Constants::Image::BOOT_DEV_SAN
        
        instance.volumes_dataset.attached.each { |volume|
          volume.volume_type = 'Dcmgr::Models::IscsiVolume'
          volume.volume_device.tap { |vd|
            vd.storage_node_id = volume.storage_node_id
            vd.iqn = volume.transport_information[:iqn]
            vd.lun = volume.transport_information[:lun]
            vd.save_changes
          }
          volume.save_changes
          
          if volume.boot_dev == 1
            instance.boot_volume_id = volume.canonical_uuid
          end
        }
        
        instance.save_changes
      }
    end
  end
end
  
