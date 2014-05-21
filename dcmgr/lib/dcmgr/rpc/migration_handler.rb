# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'

module Dcmgr
  module Rpc
    class MigrationHandler < EndpointBuilder
      include Dcmgr::Logger
      include Helpers::CliHelper
      include HvaHandler::Helpers

      job :run_vol_store, proc {
        # create hva context
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @hva_ctx.logger.info("Booting #{@inst_id}")
        raise "Invalid instance state: #{@inst[:state]}" unless %w(migrating).member?(@inst[:state].to_s)
        #if !@inst[:volume].values.all? {|v| v[:state].to_s == 'attached' }
        ## 
        #end
        
        # setup vm data folder
        FileUtils.mkdir(@hva_ctx.inst_data_dir) unless File.exists?(@hva_ctx.inst_data_dir)

        # volume: available -> attaching
        @inst[:volume].each {|volume_id, v|
          unless @hva_ctx.inst[:volume][volume_id]
            raise "Unknown volume ID for #{@hva_ctx.inst_id}: #{volume_id}"
          end

          unless @hva_ctx.inst[:volume][volume_id][:is_local_volume]
            @hva_ctx.logger.info("Attaching #{volume_id} to host node #{@node.node_id}")
            
            task_session.invoke(@hva_ctx.hypervisor_driver_class,
                                :attach_volume_to_host, [@hva_ctx, volume_id])
          end
        }

        # run vm
        setup_metadata_drive

        check_interface
        dest_params = task_session.invoke(@hva_ctx.hypervisor_driver_class,
                                          :run_migration_instance, [@hva_ctx])
        @hva_ctx.logger.info("Started migration waiting instance: #{dest_params}")

        job.submit("migration-handle.#{@inst[:host_node][:node_id]}", "start_migration",
                   @inst_id, @node.node_id, dest_params)
      }, proc {
        # incoming instance needs to care for local resources,
        # process and local files, as it is not tracked instance until
        # migration process completes. 
        ignore_error { terminate_instance(false) }
        ignore_error { update_instance_state({:state=>:running}) }
      }

      job :start_migration, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]
        @dest_node_id = request.args[1]
        @dest_params = request.args[2]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        @hva_ctx.logger.info("Started the live migration")
        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :start_migration, [@hva_ctx, @dest_params])
        @hva_ctx.logger.info("Watching the live migration")
        task_session.invoke(@hva_ctx.hypervisor_driver_class,
                            :watch_migration, [@hva_ctx])

        # shutdown source instance.
        terminate_instance(false)
        
        rpc.request('hva-collector', 'switch_instance_host_node', @inst_id, @dest_node_id)

        update_instance_state({:state=>:running})

        @hva_ctx.logger.info("Finished the live migration")
      }, proc {
        ignore_error {
          update_instance_state({:state=>:running})
        }
      }

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end
  end
end
