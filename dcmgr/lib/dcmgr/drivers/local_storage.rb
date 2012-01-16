# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class LocalStorage < SnapshotStorage
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def download(filename)
      from = File.join(@volume_snaphost_path, filename)
      to   = self.snapshot(filename)

      logger.debug("copying #{from} to #{to}")
      sh("/bin/cp -p %s %s", [from, to])
    end

    def upload(filename)
      logger.debug("checking snapshot directory #{@volume_snaphost_path}")
      Dir.mkdir(@volume_snaphost_path) unless File.exists?(@volume_snaphost_path)
      sh("/bin/mv %s %s", [self.snapshot(filename), File.join(@volume_snaphost_path, filename)])
    end

    def delete(filename)
      sh("rm -f %s", [File.join(@volume_snaphost_path, filename)])
    end
  end
end
