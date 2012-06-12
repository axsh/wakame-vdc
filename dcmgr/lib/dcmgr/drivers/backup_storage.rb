# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  # Backup storage operations.
  # upload/donwload/delete items on the backup stroage.
  class BackupStorage

    def initialize(backup_storage, opts={})
      @backup_storage = backup_storage
      @opts = opts
    end

    # Upload volume file to the backup storage.
    # @param src_path the local path to upload.
    # @param dst_key  destination key(path) to upload. Relative path
    #                 info will be given.
    #
    # Note that the dst_key will have a relative path so that it has to
    # craft the absolete destination using the additional parameter given
    # at creating this object.
    #
    # @example
    #  upload('/home/xxxx/tmp/upload.img', 'to/be/uploaded.img')
    #
    def upload(src_path, dst_key)
      raise NotImplementedError
    end

    # Download volume file from the backup storage.
    # @param src_key  source key(path) to download. Relative path
    #                 info will be given.
    # @param dst_path  local path to download.
    #
    # @example
    #  download('to/be/downloaded.img', '/home/xxxx/images/donwloaded.img')
    def download(src_key, dst_path)
      raise NotImplementedError
    end

    def delete(dst_key)
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
  
