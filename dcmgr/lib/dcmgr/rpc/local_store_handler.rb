# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'

module Dcmgr
  module Rpc
    # Inherit from HvaHandler to reuse utility methods in the class.
    class LocalStoreHandler < HvaHandler
      include Dcmgr::Logger

      concurrency Dcmgr.conf.local_store.thread_concurrency.to_i
      job_thread_pool Isono::ThreadPool.new(Dcmgr.conf.local_store.thread_concurrency.to_i, "LocalStore")

      job :run_local_store, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @hva_ctx.logger.info("Booting #{@inst_id}: phase 1")

        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:initializing})

        task_session.invoke(Drivers::LocalStore.driver_class(@inst[:host_node][:hypervisor]),
                            :deploy_image, [@inst, @hva_ctx])

        job.submit("hva-handle.#{@node.node_id}", 'run_local_store', @inst_id)
      }, proc {
        ignore_error { terminate_instance(false) }
        ignore_error {
          update_instance_state_to_terminated({:state=>:terminated, :terminated_at=>Time.now.utc})
        }
      }

      job :backup_image, proc {
        @inst_id = request.args[0]
        @backupobject_id = request.args[1]
        @image_id = request.args[2]
        @hva_ctx = HvaContext.new(self)

        @hva_ctx.logger.info("Taking backup of the image: #{@image_id}, #{@backupobject_id}")
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @bo = rpc.request('sta-collector', 'get_backup_object', @backupobject_id)
        @os_devpath = File.expand_path("#{@hva_ctx.inst[:uuid]}", @hva_ctx.inst_data_dir)

        raise "Invalid instance state (expected running): #{@inst[:state]}" unless ['running', 'halted'].member?(@inst[:state].to_s)
        #raise "Invalid volume state: #{@volume[:state]}" unless %w(available attached).member?(@volume[:state].to_s)

        rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:state=>:creating}) do |req|
          req.oneshot = true
        end
        rpc.request('hva-collector', 'update_image', @image_id, {:state=>:creating}) do |req|
          req.oneshot = true
        end

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
              rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:progress=>value[0]}) do |req|
                req.oneshot = true
              end
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

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end
  end
end
