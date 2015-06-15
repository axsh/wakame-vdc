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

        # incoming VM does not have to deal with chaging instance &
        # volume state.
        setup_shared_volume_instance

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

      job :initialize_halted_instance, proc {
        @hva_ctx = HvaContext.new(self)
        @inst_id = request.args[0]

        @hva_ctx.logger.info("Start to initialize instance")
        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)

        unless %w(migrating).member?(@inst[:state].to_s)
          raise "Invalid instance state: #{@inst[:state]}"
        end
        # it does not need to handle volume's state here.
        setup_volume_instance
        update_instance_state({:state=>:halted})
        @hva_ctx.logger.info("Finish to initialize instance")
      }

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end
    end
  end
end
