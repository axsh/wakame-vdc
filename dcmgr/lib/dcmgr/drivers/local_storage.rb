# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class LocalStorage < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def download(src_bo, dst_path)
      sh("/bin/cp %s %s", [normalize_path(abs_path(src_bo)), normalize_path(dst_path)])
    end

    def upload(src_path, dst_bo)
      sh("/bin/cp %s %s", [normalize_path(src_path), normalize_path(abs_path(dst_bo))])
    end

    def delete(filename)
      sh("rm -f %s", abs_path(filename))
    end

    private
    def abs_path(bo)
      @backup_object[:base_uri] + bo[:object_key]
    end

    def normalize_path(path)
      URI.parse(path).path
    end
  end
end
