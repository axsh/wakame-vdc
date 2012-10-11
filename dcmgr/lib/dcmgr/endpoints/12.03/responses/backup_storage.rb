# -*- coding: utf-8 -*-

module Dcmgr::Endpoints::V1203::Responses
  class BackupStorage < Dcmgr::Endpoints::ResponseGenerator
    def initialize(backup_storage)
      raise ArgumentError if !backup_storage.is_a?(Dcmgr::Models::BackupStorage)
      @backup_storage = backup_storage
    end

    def generate()
      @backup_storage.instance_exec {
        {
          :id => canonical_uuid,
          :uuid => canonical_uuid,
          :display_name => display_name,
          :storage_type => storage_type,
          :description => description,
          :base_uri => base_uri,
          :created_at => created_at,
          :updated_at => updated_at,
          :deleted_at => deleted_at,
        }
      }
    end
  end

  class BackupStorageCollection < Dcmgr::Endpoints::ResponseGenerator
    def initialize(ds)
      raise ArgumentError if !ds.is_a?(Sequel::Dataset)
      @ds = ds
    end

    def generate()
      @ds.all.map { |i|
        BackupStorage.new(i).generate
      }
    end
  end
end
