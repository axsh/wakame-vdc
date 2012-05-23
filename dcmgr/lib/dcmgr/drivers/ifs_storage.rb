# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class IfsStorage < SnapshotStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def download(filename)
    end

    def upload(filename)
      
    end

    def delete(filename)
      #ifs_filename = filename.split(".").first
      #p @bucket
      tmp_arr = @volume_snaphost_path.split ":"
      port = tmp_arr.first
      path = tmp_arr.last
      sh "curl -s http://#{@bucket}:#{port}/ifsutils/#{path}/#{filename}?delete"
    end
  end
end
