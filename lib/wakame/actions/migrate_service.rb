
module Wakame
  module Actions
    class MigrateService < Action
      def initialize(svc, dest_cloud_host=nil)
        raise ArgumentError unless svc.is_a?(Service::ServiceInstance)
        @svc = svc
        @dest_cloud_host = dest_cloud_host
      end

      def run
        acquire_lock(@svc.resource.class.to_s)
        @svc.reload

        if @svc.status == Service::STATUS_MIGRATING 
          Wakame.log.info("Ignore to migrate the service as is already MIGRATING: #{@svc.resource.class}")
          return
        end

        StatusDB.barrier {
          @svc.update_status(Service::STATUS_MIGRATING)
        }
        if @svc.resource.duplicable
          clone_service()
          flush_subactions
          trigger_action(StopService.new(@svc))
          @svc.reload
        else
          trigger_action(StopService.new(@svc))
          @svc.reload
          flush_subactions
          clone_service()
        end
        flush_subactions
      end

      def on_failed
        StatusDB.barrier {
          @svc.update_status(Service::STATUS_FAIL)
          if @new_svc
            @new_svc.update_status(Service::STATUS_FAIL)
          end
        }
      end

      private
      def clone_service()
        new_svc = nil
        StatusDB.barrier {
          new_svc = service_cluster.propagate_service(@svc.id, @dest_cloud_host, true)
        }

        trigger_action(StartService.new(new_svc))
        @new_svc = new_svc
      end
    end
  end
end
