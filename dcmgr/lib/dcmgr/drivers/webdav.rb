# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class Webdav < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::Cgroup::CgroupContextProvider
    include Dcmgr::Helpers::CliHelper

    # Note on CommandAPI (shell onliner) support.
    #
    # For PUT operation, some of DAV servers lacks to support
    #   Transfer-Encoding: chunked
    # Oneliner command line requires the chunked transfer support
    # because it can not determine the complete byte length prior to send body.
    #
    # Following web servers support chunked transfer for PUT:
    #    Apache >2.2
    #    Nginx >1.3.9
    include CommandAPI

    attr_accessor :upload_base_uri
    
    def download_command(src_bo, dst_path)
      ["curl -s %s", [abs_uri(src_bo)]]
    end

    def upload_command(src_path, dst_bo)
      ["curl -s -H 'Transfer-Encoding: chunked' --upload-file - '%s'", [abs_uri(dst_bo)]]
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
      base = (@upload_base_uri || bo[:backup_storage][:base_uri]).to_s
      base += '/' if base !~ /\/$/
      base + bo[:object_key]
    end
  end
end

