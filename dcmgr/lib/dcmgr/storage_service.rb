# -*- coding: utf-8 -*-

module Dcmgr
  class StorageService

    @snapshot_repository_config = nil
    
    def initialize(provider, access_key, secret_key)
      @account = {}
      @account[:provider] = provider.upcase
      @account[:access_key] = access_key
      @account[:secret_key] = secret_key
    end
    
    def self.snapshot_repository_config
      if @snapshot_repository_config.nil?
        config_file = YAML.load_file(File.join(File.expand_path(DCMGR_ROOT), 'config', 'snapshot_repository.yml'))
        @snapshot_repository_config = config_file
      else
        @snapshot_repository_config
      end
    end

    def self.has_driver?(driver)
      %w(S3 IIJGIO).include? driver.upcase
    end
    
    def bucket(name)
      case @account[:provider]
        when 'S3'
          @driver = Dcmgr::Drivers::S3Storage.new(name)
        when 'IIJGIO'
          @driver = Dcmgr::Drivers::IIJGIOStorage.new(name)
      else
        raise "#{@account[:provider]} is not a recognized storage provider"
      end

      @driver.setenv('SERVICE', @account[:provider].downcase)
      @driver.setenv('ACCESS_KEY_ID', @account[:access_key])
      @driver.setenv('SECRET_ACCESS_KEY', @account[:secret_key])
      @driver
    end

    def self.repository(repository_address)
      if repository_address.nil?
        return {} 
      end
      tmp = repository_address.split(',')
      destination_key = tmp[0]
      dest = destination_key.match(/^([a-z0-9_]+)@([a-z0-9_-]+):([a-z0-9_-]+):([a-z0-9_\-\/]+)(snap-[a-z0-9]+\.zsnap)+$/)
      if dest.nil?
        raise "Invalid format: #{repository_address}"
      end 
          
      h = { 
        :destination => dest[1],
        :driver => dest[2],
        :bucket => dest[3],
        :path => dest[4],
        :filename => dest[5],
        :access_key => tmp[1],
        :secret_key => tmp[2],
      }   
    end 

    def self.repository_address(destination_key)
      format = '%s,%s,%s'
      config_data = self.snapshot_repository_config
      destination = destination_key.split('@')[0]
      
      if destination == 'local'
        config = {:access_key => '', :secret_key => ''}
      else
        config = config_data[destination]
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
        store_path = "snapshots/#{account_id}/"
      end
      sprintf(format, *[destination, config["driver"], config["bucket"], File.join(store_path, filename)])
    end
  end
end
