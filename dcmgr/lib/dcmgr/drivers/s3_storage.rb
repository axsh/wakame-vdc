# -*- coding: utf-8 -*-

module Dcmgr::Drivers

  class S3Storage < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::SnapshotStorageHelper

    def download(src_key, dst_path)
      cmd = "get %s %s %s"
      args = [bucket_name(@backup_storage[:base_uri]), src_key, dst_path]
      execute(cmd, args)
    end

    def upload(src_path, dst_key)
      cmd = "put %s %s %s"
      args = [bucket_name(@backup_storage[:base_uri]), dst_key, src_path]
      execute(cmd, args)
    end

    def delete(filename)
      cmd = "rm %s %s"
      args = [bucket_name(@backup_storage[:base_uri]), filename]
      execute(cmd, args)
    end
  end
end
