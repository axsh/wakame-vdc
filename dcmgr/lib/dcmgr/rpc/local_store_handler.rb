# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'

module Dcmgr
  module Rpc
    # Inherit from HvaHandler to reuse utility methods in the class.
    class LocalStoreHandler < HvaHandler
      include Dcmgr::Logger
      C = Dcmgr::Constants

      thread_concurrency = Dcmgr::Configurations.hva.local_store.thread_concurrency.to_i

      concurrency(thread_concurrency)
      job_thread_pool Isono::ThreadPool.new(thread_concurrency, "LocalStore")

      def each_all_local_volumes(&blk)
        @inst[:volume].values.find_all { |v|
          v[:is_local_volume]
        }.each { |v|
          blk.call(v)
        }
      end

      def local_store_driver_class
        hv_klass = Drivers::Hypervisor.driver_class(@inst[:host_node][:hypervisor])
        hv_klass.local_store_class
      end

      def deploy_local_volume(volume_hash)
        v = volume_hash
        opts = {}
        if v[:backup_object]
          opts[:cache] = (
            @inst[:image][:backup_object_id] == v[:backup_object_id] &&
            @inst[:image][:is_cacheable] == 1
          )

          @hva_ctx.logger.info("Creating volume #{v[:uuid]} from #{v[:backup_object_id]}.")
          # create volume from backup object.
          task_session.invoke(local_store_driver_class,
                              :deploy_volume, [@hva_ctx, v, v[:backup_object], opts])
        else
          @hva_ctx.logger.info("Creating blank volume #{v[:uuid]}.")
          task_session.invoke(local_store_driver_class,
                              :deploy_blank_volume, [@hva_ctx, v])
        end

        update_volume_state(v[:uuid], {:state=>C::Volume::STATE_AVAILABLE}, 'hva/volume_available')
      end

      # setup local volume then run instance.
      # setup single local volume then attach.
      job :deploy_volume_and_attach, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @vol_id = request.args[0]
        @inst_id = request.args[1]
        @hva_ctx.logger.info("Booting #{@inst_id}: phase 1")

        @volume = rpc.request('sta-collector', 'get_volume',  @vol_id)
        raise "Invalid volume state: #{@inst[:state]}" unless C::Volume::DEPLOY_STATES.member?(@volume[:state].to_s)

        deploy_local_volume(@volume)

        job.submit("hva-handle.#{@node.node_id}", 'attach_volume', @inst_id, @vol_id)
      }, proc {
        ignore_error {
          update_instance_state_to_terminated({:state=>:terminated, :terminated_at=>Time.now.utc})
        }
      }

      job :delete_volume, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)
        @volume = rpc.request('sta-collector', 'get_volume',  @vol_id)

        if @volume[:state].to_s != 'deleting'
          @hva_ctx.logger.warn("Unexpected state #{@volume[:state]} of #{@vol_id}. But try to delete.")
        end

        ignore_error {
          task_session.invoke(local_store_driver_class,
                              :delete_volume, [@hva_ctx, @volume])
        }
        update_volume_state(@volume[:uuid], {:state=>:deleted, :deleted_at=>Time.now.utc},
                            'hva/volume_deleted')
      }

      # setup all local volumes and triggers run instance.
      job :run_local_store, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @hva_ctx.logger.info("Booting #{@inst_id}: phase 1")

        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)

        unless %w(pending failingover).member?(@inst[:state].to_s)
          raise "Invalid instance state: #{@inst[:state]}"
        end

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:initializing})

        each_all_local_volumes do |v|
          deploy_local_volume(v)
        end

        job.submit("hva-handle.#{@node.node_id}", 'run_local_store', @inst_id)
      }, proc {
        each_all_local_volumes do |v|
          ignore_error {
            @hva_ctx.logger.info("Cleaning volume #{v[:uuid]}")
            # create volume from backup object.
            task_session.invoke(local_store_driver_class,
                                :delete_volume, [@hva_ctx, v])
          }
          ignore_error {
            update_volume_state(v[:uuid], {:state=>:available}, 'hva/volume_available')
          }
        end
        ignore_error {
          update_instance_state_to_terminated({:state=>:terminated, :terminated_at=>Time.now.utc})
        }
      }

      job :backup_volume, proc {
        @inst_id = request.args[0]
        @volume_id = request.args[1]
        @backupobject_id = request.args[2]
        @hva_ctx = HvaContext.new(self)

        @hva_ctx.logger.info("Taking backup #{@backupobject_id} from the volume: #{@volume_id}")
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @bo = rpc.request('sta-collector', 'get_backup_object', @backupobject_id)

        @volume = @inst[:volume][@volume_id]

        raise "Invalid volume state: #{@volume[:state]}" unless %w(available attached).member?(@volume[:state].to_s)
        if @volume[:state].to_s == 'attached'
          raise "Invalid instance state (expected running): #{@inst[:state]}" unless ['running', 'halted'].member?(@inst[:state].to_s)
        end

        begin
          ev_callback = ProgressCallback.new { |cmd, *value|
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
          }
        rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:state=>:creating})
        task_session.invoke(local_store_driver_class,
                            :upload_volume, [@hva_ctx, @volume, @bo, ev_callback])
        rescue => e
          @hva_ctx.logger.error("Failed to upload image backup object: #{@backupobject_id}")
          raise
        end

        rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:state=>:available})
        @hva_ctx.logger.info("Uploaded new backup object successfully: #{@backupobject_id}")
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {:state=>:deleted, :deleted_at=>Time.now.utc}) do |req|
          req.oneshot = true
        end
        @hva_ctx.logger.error("Failed to run backup_volume: #{@backupobject_id}")
      }

      class ProgressCallback
        def initialize(&blk)
          @callee = blk
        end

        def setattr(checksum, alloc_size)
          @callee.call(:setattr, checksum, alloc_size)
        end

        def progress(percent)
          if !(0.0 > percent.to_f)
            percent = 0
          elsif 100.0 < percent.to_f
            percent = 100
          end
          @callee.call(:progress, percent)
        end
      end

      job :backup_image, proc {
        @inst_id = request.args[0]
        @backupobject_id = request.args[1]
        @image_id = request.args[2]
        @hva_ctx = HvaContext.new(self)

        @hva_ctx.logger.info("Taking backup of the image: #{@image_id}, #{@backupobject_id}")
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @bo = rpc.request('sta-collector', 'get_backup_object', @backupobject_id)

        accepted_states = [C::Instance::STATE_RUNNING, C::Instance::STATE_HALTED]
        unless accepted_states.member?(@inst[:state].to_s)
          raise "Invalid instance state. Expected one of '%s'. Got '%s'" %
            [accepted_states.join(','), @inst[:state]]
        end

        rpc.request('sta-collector', 'update_backup_object',
          @backupobject_id, {state: C::BackupObject::STATE_CREATING})

        rpc.request('hva-collector', 'update_image',
          @image_id, {state: C::Image::STATE_CREATING})

        begin
          snap_filename = @hva_ctx.os_devpath

          ev_callback = ProgressCallback.new { |cmd, *value|
            case cmd
            when :setattr
              # update checksum & allocation_size of the backup object
              rpc.request('sta-collector', 'update_backup_object', @backupobject_id, {
                            :checksum=>value[0],
                            :allocation_size => value[1],
                          })
            when :progress
              # update upload progress of backup object
              rpc.request('sta-collector', 'update_backup_object',
                @backupobject_id, {:progress=>value[0]}) do |req|
                  req.oneshot = true
                end
            else
              raise "Unknown callback command: #{cmd}"
            end
          }

          @hva_ctx.logger.info("Uploading #{snap_filename} (#{@backupobject_id})")
          task_session.invoke(local_store_driver_class,
                              :upload_image, [@inst, @hva_ctx, @bo, ev_callback])

          @hva_ctx.logger.info("Uploaded #{snap_filename} (#{@backupobject_id}) successfully")

        rescue => e
          @hva_ctx.logger.error("Failed to upload image backup object: #{@backupobject_id}")
          raise
        end

        rpc.request('sta-collector', 'update_backup_object',
          @backupobject_id, {state: C::BackupObject::STATE_AVAILABLE})

        rpc.request('hva-collector', 'update_image',
          @image_id, {state: C::Image::STATE_AVAILABLE})

        @hva_ctx.logger.info("Uploaded new image successfully: #{@image_id} #{@backupobject_id}")
      }, proc {
        # TODO: need to clear generated temp files or remote files in remote snapshot repository.
        rpc.request('sta-collector', 'update_backup_object', @backupobject_id,
          {state: C::BackupObject::STATE_DELETED, deleted_at: Time.now.utc}) do |req|
            req.oneshot = true
          end

        rpc.request('hva-collector', 'update_image', @image_id,
          {state: C::Image::STATE_DELETED, deleted_at: Time.now.utc}) do |req|
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
