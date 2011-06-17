# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  
  class IIJGIOStorage < SnapshotStorage
   
    def download(keyname, filename, path) 
      cmd = "get %s %s %s" 
      args = [@bucket, keyname, File.join(path, filename)]
      execute(cmd, args)
    end

    def upload(keyname, file)
      cmd = "put %s %s %s"
      args = [@bucket, keyname, file]
      execute(cmd, args)
    end

    def delete(keyname)
      cmd = "rm %s %s"
      args = [@bucket, keyname]
      execute(cmd, args)
    end

    def check(keyname)
      cmd = "test %s %s"
      args = [@bucket, keyname]
      execute(cmd, args)
    end
    
    def list
      cmd = "ls %s"
      args = [@bucket]
      execute(cmd, args)
    end
  end
end
