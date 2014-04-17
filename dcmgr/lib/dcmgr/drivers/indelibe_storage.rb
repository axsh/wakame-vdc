# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class IndelibeStorage < BackupStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::IndelibleApi

    def download(src_bo, dst_path)
    end

    def upload(src_path, dst_bo)
    end

    def delete(filename)
      ifsutils(filename, :delete)
    end
  end
end
