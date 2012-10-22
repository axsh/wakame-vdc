# -*- coding: utf-8 -*-

require 'uri'

module Dcmgr::Drivers
  class LocalStorage < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::Cgroup::CgroupContextProvider
    include Dcmgr::Helpers::CliHelper

    include CommandAPI

    def download_command(src_bo, dst_path)
      ["cat %s", [normalize_path(abs_path(src_bo))]]
    end

    def upload_command(src_path, dst_bo)
      ["cat > %s", [normalize_path(abs_path(dst_bo))]]
    end

    def download(src_bo, dst_path)
      sh("/bin/cp %s %s", [normalize_path(abs_path(src_bo)), normalize_path(dst_path)])
    end

    def upload(src_path, dst_bo)
      sh("/bin/cp %s %s", [normalize_path(src_path), normalize_path(abs_path(dst_bo))])
    end

    def delete(bo)
      sh("rm -f %s", [abs_path(bo)])
    end

    private
    def abs_path(bo)
      (Dcmgr.conf.backup_storage.local_storage_dir || bo[:backup_storage][:base_uri]) + bo[:object_key]
    end

    def normalize_path(path)
      URI.parse(path).path
    end
  end
end
