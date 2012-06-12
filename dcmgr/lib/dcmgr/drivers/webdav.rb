# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class Webdav < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def upload(src_path, dst_bo)
      sh("curl -q -T %s %s", [src_path, abs_uri(dst_bo)])
    end

    def download(src_bo, dst_path)
      sh("curl -q -o %s %s", [dst_path, abs_uri(src_bo)])
    end

    def delete
      raise NotImplementedError
    end

    private
    def abs_uri(bo)
      @backup_storage[:base_uri] + bo[:object_key]
    end
  end
end
  
