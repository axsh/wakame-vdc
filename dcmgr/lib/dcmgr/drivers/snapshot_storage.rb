# -*- coding: utf-8 -*-

module Dcmgr::Drivers
  class SnapshotStorage
    include Dcmgr::Helpers::CliHelper
    attr_reader :volume_snaphost_path

    def initialize(account_id, bucket, volume_snaphost_path)
      @account_id = account_id
      @env = []
      @volume_snaphost_path = volume_snaphost_path
      @bucket = bucket
    end

    def setenv(key, value)
      @env.push("#{key}=#{value}")
    end
    
    def clear
      sh("/bin/rm #{@temporary_file}") if File.exists?(@temporary_file)
    end

    def snapshot(filename)
      raise 'filename is empty' if filename == ''
      @temporary_file = File.join('/tmp', filename)
    end

    def download(filename)
    end

    def upload(filename)
    end

    def delete(filename)
    end

    def check(filename)
    end
  end
end
