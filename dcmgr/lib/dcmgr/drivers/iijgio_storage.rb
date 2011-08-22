# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  
  class IIJGIOStorage < SnapshotStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::SnapshotStorageHelper

    def download(filename) 
      cmd = "get %s %s %s" 
      args = [@bucket, key(filename), self.snapshot(filename)]
      execute(cmd, args)
    end

    def upload(filename)
      cmd = "put %s %s %s"
      args = [@bucket, key(filename), self.snapshot(filename)]
      execute(cmd, args)
    end

    def delete(filename)
      cmd = "rm %s %s"
      args = [@bucket, key(filename)]
      execute(cmd, args)
    end
  end
end
