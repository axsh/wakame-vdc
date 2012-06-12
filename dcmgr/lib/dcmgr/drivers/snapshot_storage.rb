# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class SnapshotStorage
    include Dcmgr::Helpers::CliHelper
    attr_reader :volume_snaphost_path

    #def initialize(bucket, volume_snaphost_path, options = {})
    def initialize(backup_storage, options = {})
      @env = []
      @backup_storage = backup_storage
      @options = options
    end

    def setenv(key, value)
      @env.push("#{key}=#{value}")
    end
    
    def download(src_bo, dst_path)
      raise NotImplementedError
    end

    def upload(src_path, dst_bo)
      raise NotImplementedError
    end

    def delete(filename)
      raise NotImplementedError
    end

    def check(filename)
      raise NotImplementedError
    end

    def self.snapshot_storage(backup_storage, opts={})
      storage = case backup_storage[:storage_type]
                when 'local'
                  LocalStorage.new(backup_storage, opts)
                when 's3'
                  S3Storage.new(backup_storage, opts)
                when 'iijgio'
                  IIJGIOStorage.new(backup_storage, opts)
                when 'ifs'
                  IfsStorage.new(backup_storage, opts)
                when 'webdav'
                  Webdav.new(backup_storage, opts)
                else
                  raise "Unknown backup storage driver: #{backup_storage[:storage_type]}"
                end
      storage
    end
  end
end
