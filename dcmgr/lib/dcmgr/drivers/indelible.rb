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
    end

    def initialize()
      super
      @webapi_port = Dcmgr.conf.backing_store.webapi_port
      @webapi_ip   = Dcmgr.conf.backing_store.webapi_ip
    end

    def create_volume(ctx, snap_file = nil)
      @volume_id   = ctx.volume_id
      @volume      = ctx.volume
      #TODO: Nilchecks... how many do we need here?
      @webapi_ip = @volume[:volume_device][:iscsi_storage_node][:ip_address]
      @vol_path = @volume[:volume_device][:iscsi_storage_node][:export_path]

      ifsutils(@vol_path, :mkdir) unless directory_exists?(@vol_path)

      if @snapshot
        snap_path = @snapshot[:destination_key].split(":").last
        new_vol_path = @vol_path.split("/",2).last

        ifsutils(snap_path, :duplicate, dest: "#{new_vol_path}/#{@volume_id}")
      else
        path = "#{@vol_path}/#{@volume_id}"
        ifsutils(path, :allocate, size: "#{@volume[:size]}") { |result|
          e = result["error"]
          if e
            raise "Indelibe FS error code #{e["code"]}. Long reason:\n#{e["longReason"]}"
          end
        }
      end

      logger.info("created new volume: #{@volume_id}")
    end

    def delete_volume(ctx)
      @webapi_ip = ctx.volume[:volume_device][:iscsi_storage_node][:ip_address]
      vol_path   = ctx.volume[:volume_device][:iscsi_storage_node][:export_path]

      logger.info("Deleting volume: #{ctx.volume_id}")
      ifsutils("#{vol_path}/#{ctx.volume_id}", :delete)
    end

    def create_snapshot(ctx)
      @volume    = ctx.volume
      @vol_path  = @volume[:volume_device][:iscsi_storage_node][:export_path]
      @webapi_ip = @volume[:volume_device][:iscsi_storage_node][:ip_address]

      new_snap_path = snapshot_path(ctx)

      ifsutils("#{@vol_path}/#{@volume[:uuid]}", :duplicate, new_snap_path)

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
