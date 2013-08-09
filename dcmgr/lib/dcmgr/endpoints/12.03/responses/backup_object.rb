# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class BackupObject < Dcmgr::Endpoints::ResponseGenerator
    def initialize(backup_object)
      raise ArgumentError if !backup_object.is_a?(Dcmgr::Models::BackupObject)
      @backup_object = backup_object
    end

    def generate()
      @backup_object.instance_exec {
        {:id => canonical_uuid,
          :uuid => canonical_uuid,
          :account_id => account_id,
          :state => state,
          :size => size,
          :allocation_size => allocation_size,
          :backup_storage_id => backup_storage.canonical_uuid,
          :object_key => object_key,
          :checksum => checksum,
          :progress => progress,
          :backup_storage => {
            :id => backup_storage.canonical_uuid,
          },
          :description => description,
          :display_name => display_name,
          :service_type => service_type,
          :created_at => created_at,
          :updated_at => updated_at,
          :deleted_at => deleted_at,
          :labels=>resource_labels.map{ |l| ResourceLabel.new(l).generate },
        }
      }
    end
  end

  class BackupObjectCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        BackupObject.new(i).generate
      }
    end
  end
end
