# -*- coding: utf-8 -*-

module Dcmgr
  class StorageService
    def initialize(provider, access_key, secret_key)
      @account = {}
      @account[:provider] = provider.upcase
      @account[:access_key] = access_key
      @account[:secret_key] = secret_key
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

    def self.get_destination(destination_key)
      if destination_key.nil?
        return {
          :driver => 'local'
        }
      end

      keys = destination_key.split(":")
      h = { 
        :driver => keys[0],
        :bucket => keys[1],
        :key => keys[2],
        :path => keys[3],
        :access_key => keys[4],
        :secret_key => keys[5],
      }   
    end 
  
    def self.generate_destination_key(destination, account_id, filename)
    
      format = '%s:%s:%s:%s:%s:%s'

      config_path = File.join(File.expand_path('../../'), 'config')
      config_filename = 'snapshot_repository.yml'
      config_data = YAML.load_file(File.join(config_path, config_filename))
      config = config_data[destination]
    
      if config
        driver = config['driver']
        bucket = config['bucket']
        path = "snapshots/#{account_id}/"
        key = "#{filename}.zsnap"
        access_key = config['access_key']
        secret_key = config['secret_key']
      else
        driver = 'local'
        bucket = key = path = ''
        access_key = secret_key = ''
      end 

      sprintf(format, *[driver, bucket, key, path, access_key, secret_key])
    end 

  end
end
