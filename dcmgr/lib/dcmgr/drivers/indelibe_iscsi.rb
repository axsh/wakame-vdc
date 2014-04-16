# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr::Drivers
  class IndelibeIscsi < IscsiTarget
    include Dcmgr::Logger
    include Dcmgr::Helpers::IndelibleApi

    IQN_PREFIX="iqn.2010-09.jp.wakame".freeze

    def initialize()
      super
      # Hard coded for now
      @webapi_port = "8090"
    end

    def create(ctx)
      @webapi_ip = ctx.volume[:volume_device][:iscsi_storage_node][:ip_address]

      iqn = "#{IQN_PREFIX}:#{ctx.volume_id}"
      vol_path = ctx.volume[:volume_device][:iscsi_storage_node][:export_path]

      #TODO: Error handling
      ifs_iscsi("#{vol_path}/#{ctx.volume_id}", :export, target: iqn)

      { :iqn => iqn, :lun => 0 }
    end

    def delete(ctx)
      @webapi_ip = ctx.volume[:volume_device][:iscsi_storage_node][:ip_address]

       ifs_iscsi("", :unexport, target: "#{IQN_PREFIX}:#{ctx.volume_id}")
    end
  end
end
