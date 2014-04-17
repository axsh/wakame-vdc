# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr::Drivers
  class IndelibleIscsi < IscsiTarget
    include Dcmgr::Logger
    include Dcmgr::Helpers::IndelibleApi

    def_configuration do
      param :webapi_ip, default: "127.0.0.1"
      param :webapi_port, default: 8090
    end

    def initialize()
      super
      @iqn_prefix  = Dcmgr.conf.iscsi_target.iqn_prefix
      @webapi_ip   = Dcmgr.conf.iscsi_target.webapi_ip
      @webapi_port = Dcmgr.conf.iscsi_target.webapi_port
    end

    def create(ctx)
      iqn = "#{@iqn_prefix}:#{ctx.volume_id}"
      vol_path = ctx.volume[:volume_device][:iscsi_storage_node][:export_path]

      #TODO: Error handling
      ifs_iscsi("#{vol_path}/#{ctx.volume_id}", :export, target: iqn)

      { :iqn => iqn, :lun => 0 }
    end

    def delete(ctx)
       ifs_iscsi("", :unexport, target: "#{@iqn_prefix}:#{ctx.volume_id}")
    end
  end
end
