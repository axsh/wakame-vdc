# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class LocalStorage < SnapshotStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def download(filename)
      sh("/bin/cp -p %s %s", [File.join(@volume_snaphost_path, filename), self.snapshot(filename)])
    end

    def upload(filename)
      sh("/bin/mv %s %s", [self.snapshot(filename), File.join(@volume_snaphost_path, filename)])
    end

    def delete(filename)
      sh("rm -f %s", [File.join(@volume_snaphost_path, filename)])
    end
  end
end
