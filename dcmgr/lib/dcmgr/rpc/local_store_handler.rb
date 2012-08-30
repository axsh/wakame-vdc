# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'

module Dcmgr
  module Rpc
    class LocalStoreHandler < Isono::Runner::RpcServer::EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::ByteUnit

      concurrency 4
      job_thread_pool Isono::ThreadPool.new(4, "LocalStore")
      
      # syntax sugar to catch any errors and continue to work the code
      # following.
      def ignore_error(&blk)
        begin
          blk.call
        rescue ::Exception => e
          @hva_ctx.logger.error("Ignoring error: #{e.message}")
          @hva_ctx.logger.error(e)
        end
      end

      # Reset TaskSession per request.
      def task_session
        @task_session ||= begin
                            Task::TaskSession.reset!(:thread)
                            Task::TaskSession.current[:logger] = @hva_ctx.logger
                            Task::TaskSession.current
                          end
      end


      job :backup_image, proc {
        @inst_id = request.args[0]
        @backupobject_id = request.args[1]
        @image_id = request.args[2]
        @hva_ctx = HvaContext.new(self)

        @hva_ctx.logger.info("Taking backup up of the image: #{@image_id}, #{@backupobject_id}")
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @bo = rpc.request('sta-collector', 'get_backup_object', @backupobject_id)
        @os_devpath = File.expand_path("#{@hva_ctx.inst[:uuid]}", @hva_ctx.inst_data_dir)

        raise "Invalid instance state (expected running): #{@inst[:state]}" if @inst[:state].to_s != 'running'
        #raise "Invalid volume state: #{@volume[:state]}" unless %w(available attached).member?(@volume[:state].to_s)

        begin
          snap_filename = @hva_ctx.os_devpath

          ev_callback = proc { |cmd, *value|
            case cmd
            when :setattr
              # update checksum & allocation_size of the backup object
              rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {
                            :checksum=>value[0],
                            :allocation_size => value[1],
                          })
            when :progress
              # update upload progress of backup object
              #rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:progress=>value[0]}) do |req|
              #  req.oneshot = true
              #end
            else
              raise "Unknown callback command: #{cmd}"
            end
          }.tap { |i|
            i.instance_eval {
              def setattr(checksum, alloc_size)
                self.call(:setattr, checksum, alloc_size)
              end

              def progress(percent)
                self.call(:progress, percent)
              end
            }
          }

          @hva_ctx.logger.info("Uploading #{snap_filename} (#{@backupobject_id})")
          task_session.invoke(Drivers::LocalStore.driver_class(@inst[:host_node][:hypervisor]),
                              :upload_image, [@inst, @hva_ctx, @bo, ev_callback])
          
          @hva_ctx.logger.info("Uploaded #{snap_filename} (#{@backupobject_id}) successfully")
      
        rescue => e
          @hva_ctx.logger.error("Failed to upload image backup object: #{@backupobject_id}")
          raise
        end
        
        rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:state=>:available}) do |req|
          req.oneshot = true
        end
        rpc.request('hva-collector', 'update_image', @image_id, {:state=>:available}) do |req|
          req.oneshot = true
        end
        @hva_ctx.logger.info("Uploaded new image successfully: #{@image_id} #{@backupobject_id}")
        
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:state=>:deleted, :deleted_at=>Time.now.utc}) do |req|
          req.oneshot = true
        end
        rpc.request('hva-collector', 'update_image', @image_id, {:state=>:deleted, :deleted_at=>Time.now.utc}) do |req|
          req.oneshot = true
        end
        @hva_ctx.logger.error("Failed to run backup_image: #{@image_id}, #{@backupobject_id}")
      }
      

      def rpc
        @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
      end

      def jobreq
        @jobreq ||= Isono::NodeModules::JobChannel.new(@node)
      end

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end
  end
end
