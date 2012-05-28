# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class Webdav < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def initialize(opts)
      @base_uri = opts[:base_uri]
    end
    
    def upload(src_path, dst_key)
      sh("curl -q -T %s %s", [src_path, abs_uri(dst_key)])
    end

    def download(src_key, dst_path)
      sh("curl -q -O %s %s", [dst_path, abs_uri(src_key)])
    end

    def delete
      raise NotImplementedError
    end

    private
    def abs_uri(dst_key)
      @base_uri + dst_key
    end
  end
end
  
