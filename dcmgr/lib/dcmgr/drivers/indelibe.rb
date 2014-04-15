# -*- coding: utf-8 -*-

require 'fileutils'

module Dcmgr::Drivers
  class Indelibe < BackingStore
    include Dcmgr::Logger
    include Dcmgr::Helpers::CliHelper

    def initialize()
      super
      # Hard coded for now
      @port = "8091"
    end

    def create_volume(ctx, snap_file = nil)
      @volume_id   = ctx.volume_id
      @volume      = ctx.volume
      #TODO: Nilchecks... how many do we need here?
      @ip = @volume[:volume_device][:iscsi_storage_node][:ip_address]
      @vol_path = @volume[:volume_device][:iscsi_storage_node][:export_path]

      sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{@vol_path}?cmd=mkdir"

      if @snapshot
        snap_path = @snapshot[:destination_key].split(":").last
        new_vol_path = @vol_path.split("/",2).last
        sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{snap_path}?duplicate=#{new_vol_path}/#{@volume_id}"
      else
        #TODO: Check if file was created successfully
        url = "http://#{@ip}:#{@port}/ifsutils/#{@vol_path}/#{@volume_id}"
        params = "cmd=allocate&size=#{@volume[:size]}"
        sh "curl -s #{url}?#{params}"
      end

      logger.info("created new volume: #{@volume_id}")
    end

    def delete_volume(ctx)
      @volume_id = ctx.volume_id
      @volume    = ctx.volume
      @ip        = @volume[:storage_node][:ipaddr]
      @vol_path  = @volume[:storage_node][:export_path]

      logger.info("Deleting volume: #{@volume_id}")
      sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{@vol_path}/#{@volume_id}?cmd=delete"
    end

    def create_snapshot(ctx)
      @volume      = ctx.volume
      @vol_path  = @volume[:storage_node][:export_path]
      @ip        = @volume[:storage_node][:ipaddr]

      new_snap_path = snapshot_path(ctx)
      sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{@vol_path}/#{@volume[:uuid]}?duplicate=#{new_snap_path}"

      logger.info("created new snapshot: #{new_snap_path}")
    end

    # do nothing because IFS's snapshot is as same as the backup object.
    def delete_snapshot(ctx)
    end

    def snapshot_path(ctx)
      ctx.backup_object[:object_key]
    end

  end
end
