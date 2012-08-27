# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class Webdav < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::Cgroup::CgroupContextProvider
    include Dcmgr::Helpers::CliHelper

    # Note on CommandAPI (shell onliner) support.
    # 
    # For PUT operation, most of DAV servers check the Content-Length
    # header and expect to be sent from the client. The content will
    # be rejected if the header has wrong value.
    # It is difficult to send the proper size of the image file from
    # the shell oneliner without creating temporary file. Because the
    # data is transformed to different format, i.e. gzip,  then the
    # generated data size is vary while goes through the shell pipeline.
    # Therefore, this driver no longer supports shell onliner API.
    
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
  
