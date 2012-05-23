# -*- coding: utf-8 -*-

require 'fileutils'

module Dcmgr
  module Drivers
    class Ifs < BackingStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      
      def initialize()
        super
        # Hard coded for now
        @port = "8090"
      end
      
      def create_volume(ctx, snap_file = nil)
        @volume_id   = ctx.volume_id
        @volume      = ctx.volume
        @snapshot    = ctx.snapshot
        @ip = @volume[:storage_node][:ipaddr]
        @vol_path = @volume[:storage_node][:export_path]

        #@temp_path = generate_temp_path

        ##TODO: Check if the directory exists first
        sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{@vol_path}?mkdir"

        if @snapshot
          #raise NotImplementedError

          #sh "curl -X PUT -d @#{snap_file} http://#{@ip}:#{@port}/ifsutils/#{@fsid}/volumes/#{@volume_id}"
          snap_path = @snapshot[:destination_key].split(":").last
          new_vol_path = @vol_path.split("/",2).last
          sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{snap_path}?duplicate=#{new_vol_path}/#{@volume_id}"
        else
          #TODO: Check if file was created successfully
          sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{@vol_path}/#{@volume_id}?allocate=#{@volume[:size] * 1024 * 1024}"
        end

        logger.info("created new volume: #{@volume_id}")
      end
      
      def delete_volume(ctx)
        @volume_id = ctx.volume_id
        @volume    = ctx.volume
        @ip        = @volume[:storage_node][:ipaddr]
        @vol_path  = @volume[:storage_node][:export_path]
        
        logger.info("Deleting volume: #{@volume_id}")
        sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{@vol_path}/#{@volume_id}?delete"
      end
      
      def create_snapshot(ctx, snap_file)
        @volume      = ctx.volume
        @vol_path  = @volume[:storage_node][:export_path]
        @ip        = @volume[:storage_node][:ipaddr]
        @snapshot    = ctx.snapshot

        new_snap_path = @snapshot[:destination_key].split("/",2).last
        sh "curl -s http://#{@ip}:#{@port}/ifsutils/#{@vol_path}/#{@volume[:uuid]}?duplicate=#{new_snap_path}"
        raise "failed snapshot file : #{@snapshot[:filename]}" if $?.exitstatus != 0

        logger.info("created new snapshot: #{@snapshot[:filename]}")
      end
      
    end
  end
end
