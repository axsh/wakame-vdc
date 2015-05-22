# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  # Backup storage operations.
  # upload/donwload/delete items on the backup stroage.
  class BackupStorage < Dcmgr::Task::Tasklet
    module CommandAPI
      # @return Array [cmd_str, cmd_args]
      def upload_command(src_path, dst_bo)
        raise NotImplementedError
      end

      # Download volume file from the backup storage.
      # @param src_bo    BackupObject hash of the download item.
      # @param dst_path  The local path to download item.
      #
      # @example
      #  download(backup_object_hash, '/home/xxxx/images/donwloaded.img')
      # @return Array [cmd_str, cmd_args]
      def download_command(src_bo, dst_path)
        raise NotImplementedError
      end
    end

    before do
      @backup_storage = session[:backup_storage]
      @opts = session[:opts]
    end

    # Upload volume file to the backup storage.
    # @param src_path The local path to upload item.
    # @param dst_bo   BackupObject hash of the upload destination.
    #
    # @example
    #  upload('/home/xxxx/tmp/upload.img', backup_object_hash)
    #
    def upload(src_path, dst_bo)
      raise NotImplementedError
    end

    # Download volume file from the backup storage.
    # @param src_bo    BackupObject hash of the download item.
    # @param dst_path  The local path to download item.
    #
    # @example
    #  download(backup_object_hash, '/home/xxxx/images/donwloaded.img')
    def download(src_bo, dst_path)
      raise NotImplementedError
    end

    # Delete backup object file on the backup storage.
    # @param dst_bo    BackupObject hash of the delete item.
    def delete(dst_bo)
      raise NotImplementedError
    end

    def self.snapshot_storage(backup_storage, opts={})
      driver_class(backup_storage[:storage_type]).new
    end

    def self.driver_class(storage_type)
      case storage_type.to_s
      when 'local'
        LocalStorage
      when 'ifs'
        IfsStorage
      when 'webdav'
        Webdav
      else
        raise "Unknown backup storage driver: #{storage_type}"
      end
    end

  end
end

