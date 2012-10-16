# -*- coding: utf-8 -*-

module Dcmgr
  class StorageService

    @snapshot_repository_config = nil

    def initialize(driver, options = {})
      @driver = driver
      @account = {}
      @account[:id] = options[:account_id]
      @account[:access_key] = options[:access_key]
      @account[:secret_key] = options[:secret_key]
    end

    def self.snapshot_repository_config
      if @snapshot_repository_config.nil?
        config_file = YAML.load_file(File.join(File.expand_path('../../../', __FILE__), 'config', 'snapshot_repository.yml'))
        @snapshot_repository_config = config_file
      else
        @snapshot_repository_config
      end
    end

    def snapshot_storage(bucket, path)
      case @driver
        when 'local'
          @storage = Dcmgr::Drivers::LocalStorage.new(@account[:id], bucket, path)
        when 's3'
          @storage = Dcmgr::Drivers::S3Storage.new(@account[:id], bucket, path)
        when 'iijgio'
          @storage = Dcmgr::Drivers::IIJGIOStorage.new(@account[:id], bucket, path)
        when 'ifs'
          @storage = Dcmgr::Drivers::IfsStorage.new(@account[:id], bucket, path)
      else
        raise "#{@driver} is not a recognized storage driver"
      end

      @storage.setenv('SERVICE', @driver)
      @storage.setenv('ACCESS_KEY_ID', @account[:access_key])
      @storage.setenv('SECRET_ACCESS_KEY', @account[:secret_key])
      @storage
    end

    def self.repository(repository_address)
      if repository_address.nil?
        return {}
      end
      tmp = repository_address.split(',')
      destination_key = tmp[0]

      # ex. 'local@local:none:/home/ubuntu/work/repos/git/github.com/wakame-vdc/tmp/snap/a-shpoolxx/snap-gkosnc56.snap'
      # dest = destination_key.match(/^([a-z0-9_]+)@([a-z0-9_-]+):([a-z0-9_-]+):([a-z0-9._\-\/]+)(snap-[a-z0-9]+\.snap)+$/)
      results  = destination_key.split(':', 3)
      accounts = results[0].split('@', 2)

      h = {
        :destination => accounts[0],
        :driver => accounts[1],
        :bucket => results[1],
        :path => File.dirname(results[2]),
        :filename => File.basename(results[2]),
        :access_key => tmp[1],
        :secret_key => tmp[2],
      }
    end

    def self.repository_address(destination_key)
      format = '%s,%s,%s'
      config_data = self.snapshot_repository_config
      destination = destination_key.split('@')[0]

      config = if destination == 'local'
                 {'access_key' => '', 'secret_key' => ''}
               else
                 config_data[destination]
               end

      sprintf(format, *[destination_key, config["access_key"], config["secret_key"]])
    end

    def self.destination_key(account_id, destination, store_path, filename)
      format = '%s@%s:%s:%s'
      if destination == 'local'
        config = {
          "driver" => "local",
          "bucket" => "none"
        }
      else
        config_data = snapshot_repository_config
        config = config_data[destination]
        if config.nil?
          raise "Destination isn't exists"
        end
      end
      sprintf(format, *[destination, config["driver"], config["bucket"], File.join("#{store_path}/#{account_id}/", filename)])
    end
  end
end
