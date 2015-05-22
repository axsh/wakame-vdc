# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr::Drivers
  class IndelibleIscsi < IscsiTarget
    include Dcmgr::Logger
    include Dcmgr::Helpers::IndelibleApi

    def_configuration do
      param :webapi_ip, default: "127.0.0.1"
      param :webapi_port, default: 8090
      #TODO: Raise error when not provided in the config file
      param :indelible_volume
      param :wakame_volumes_dir, default: "volumes"
    end

    def initialize()
      super
      @iqn_prefix  = driver_configuration.iqn_prefix
      @webapi_ip   = driver_configuration.webapi_ip
      @webapi_port = driver_configuration.webapi_port
      indelible_volume = driver_configuration.indelible_volume
      wakame_volumes_dir = driver_configuration.wakame_volumes_dir

      @vol_path = "#{indelible_volume}/#{wakame_volumes_dir}"
    end

    def create(ctx)
      iqn = "#{@iqn_prefix}:#{ctx.volume_id}"
      #TODO: Error handling
      ifs_iscsi("#{@vol_path}/#{ctx.volume_id}", :export, target: iqn)

      { :iqn => iqn, :lun => 0 }
    end

    def delete(ctx)
       ifs_iscsi("", :unexport, target: "#{@iqn_prefix}:#{ctx.volume_id}")
    end
  end
end
