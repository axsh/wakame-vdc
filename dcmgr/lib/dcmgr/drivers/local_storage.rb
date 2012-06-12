# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class LocalStorage < SnapshotStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def download(src_bo, dst_path)
      sh("/bin/cp -p %s %s", [abs_path(src_bo), dst_path])
    end

    def upload(src_path, dst_bo)
      sh("/bin/cp -p %s %s", [src_path, abs_path(dst_bo)])
    end

    def delete(filename)
      sh("rm -f %s", abs_path(filename))
    end

    private
    def abs_path(bo)
      @backup_object[:base_uri] + bo[:object_key]
    end
  end
end
