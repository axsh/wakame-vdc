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
    
    def execute(cmd, args)
      script_root_path = File.join(File.expand_path('.'), 'script')
      script = File.join(script_root_path, 'storage_service')
      cmd = "/usr/bin/env #{@env.join(' ')} %s " + cmd
      args = [script] + args
      sh(cmd, args)
    end
  end
end
