# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class SnapshotStorage
    include Dcmgr::Helpers::CliHelper
 
    def initialize(bucket)
      @env = []
      @bucket = bucket
    end

    def setenv(key, value)
      @env.push("#{key}=#{value}")
    end

    def download
    end

    def upload
    end

    def delete
    end

    def check
    end
  end
end
