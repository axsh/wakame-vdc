# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class IndelibeStorage < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def download(src_bo, dst_path)
    end

    def upload(src_path, dst_bo)
    end

    def delete(filename)
      sh "curl -s #{@backup_storage[:base_uri]}/ifsutils/#{filename}?delete"
    end
  end
end
