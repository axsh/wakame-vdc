# -*- coding: utf-8 -*-

require 'net/http'

module Dcmgr::Drivers
  class IndelibeIscsi < IscsiTarget
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    IQN_PREFIX="iqn.2010-09.jp.wakame".freeze

    def initialize()
      super
      # Hard coded for now
      @web_ui_port = "8091"
    end

    def create(ctx)
      @ip = ctx.volume[:volume_device][:iscsi_storage_node][:ip_address]

      iqn = "#{IQN_PREFIX}:#{ctx.volume_id}"
      vol_path = ctx.volume[:volume_device][:iscsi_storage_node][:export_path]

      #TODO: Error handling
      ifs_iscsi("#{vol_path}/#{ctx.volume_id}", :export, target: iqn)

      { :iqn => iqn, :lun => 0 }
    end

    def delete(ctx)
      @ip = ctx.volume[:volume_device][:iscsi_storage_node][:ip_address]

      ifs_iscsi("", :unexport, target: "#{IQN_PREFIX}:#{ctx.volume_id}")
    end

    private
    def ifs_iscsi(uri_suffix, cmd, params = {}, &blk)
      uri = "http://#{@ip}:#{@web_ui_port}/iscsi/#{uri_suffix}?"
      params[:cmd] = cmd
      uri.concat params.to_a.map { |i| "#{i.first}=#{i.last}" }.join("&")
      logger.debug "Calling Indelibe FS server: " + uri

      JSON.parse(Net::HTTP.get(URI(uri))).tap { |output|
        blk.call(output) if block_given?
      }
    end
  end
end
