# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class Webdav < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::Cgroup::CgroupContextProvider
    include Dcmgr::Helpers::CliHelper

    include CommandAPI
    
    def upload_command(src_path, dst_bo)
      ["curl -T %s", [abs_uri(dst_bo)]]
    end

    def download_command(src_bo, dst_path)
      ["curl %s", [abs_uri(src_bo)]]
    end
    
    def upload(src_path, dst_bo)
      sh("curl -T %s %s", [src_path, abs_uri(dst_bo)])
    end

    def download(src_bo, dst_path)
      sh("curl -o %s %s", [dst_path, abs_uri(src_bo)])
    end

    def delete(bo)
      sh("curl -s -X DELETE %s", [abs_uri(bo)])
    end

    private
    def abs_uri(bo)
      bo[:backup_storage][:base_uri] + bo[:object_key]
    end
  end
end
  
