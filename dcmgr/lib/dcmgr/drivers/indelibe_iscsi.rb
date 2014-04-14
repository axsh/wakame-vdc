# -*- coding: utf-8 -*-

#require 'yaml'

module Dcmgr::Drivers
  class IndelibeIscsi < IscsiTarget
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    IQN_PREFIX="iqn.2010-09.jp.wakame".freeze

    def initialize()
      super
      # Hard coded for now
      @web_ui_port = "8090"
    end

    def create(ctx)
      @volume_id = ctx.volume_id
      @volume = ctx.volume
      @vol_path = @volume[:storage_node][:export_path]
      @snap_path = @volume[:storage_node][:snap_path]
      @ip = @volume[:storage_node][:ipaddr]

      iqn = "#{IQN_PREFIX}:#{@volume_id}"

      sh("curl -s http://#{@ip}:#{@web_ui_port}/iscsi/#{@vol_path}/#{@volume_id}?export=#{iqn}")

      { :iqn => iqn, :lun => 0, :ifs_id => @vol_path.split("/").first }
    end

    def delete(ctx)
      @volume_id = ctx.volume_id
      @volume = ctx.volume
      @ip = @volume[:storage_node][:ipaddr]

      sh("curl -s http://#{@ip}:#{@web_ui_port}/iscsi?unexport=#{IQN_PREFIX}:#{@volume_id}")
    end

  end
end
