# -*- coding: utf-8 -*-

require 'fileutils'
require 'json'
require 'net/http'

module Dcmgr::Drivers
  class Indelible < BackingStore
    include Dcmgr::Logger
    include Dcmgr::Helpers::IndelibleApi

    def_configuration do
      param :webapi_port, default: 8091
      param :webapi_ip, default: "127.0.0.1"
      #TODO: Raise error when not provided in the config file
      param :indelible_volume
      param :wakame_volumes_dir, default: "volumes"
    end

    def initialize()
      super
      @webapi_port = driver_configuration.webapi_port
      @webapi_ip   = driver_configuration.webapi_ip
      indelible_volume = driver_configuration.indelible_volume
      wakame_volumes_dir = driver_configuration.wakame_volumes_dir

      @vol_path = "#{indelible_volume}/#{wakame_volumes_dir}"
    end

    def create_volume(ctx, snap_file = nil)
      volume_id = ctx.volume_id

      ifsutils(@vol_path, :mkdir) unless directory_exists?(@vol_path)

      path = "#{@vol_path}/#{volume_id}"
      ifsutils(path, :allocate, size: "#{ctx.volume[:size]}") { |result|
        if result["error"]
          raise "Indelibe FS error code %s. Long reason:\n%s}" %
            [result["error"]["code"], result["error"]["longReason"]]
        end
      }

      logger.info("created new volume: #{volume_id}")
    end

    def delete_volume(ctx)
      logger.info("Deleting volume: #{ctx.volume_id}")
      ifsutils("#{@vol_path}/#{ctx.volume_id}", :delete)
    end
  end
end
