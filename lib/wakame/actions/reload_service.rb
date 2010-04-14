module Wakame
  module Actions
    class ReloadService < Action
      def initialize(svc)
        @svc = svc
      end

      def run
        # Skip to act when the service is having below status.
        if @svc.monitor_status != Service::STATUS_ONLINE
          raise "Canceled as the service is being or already ONLINE: #{@svc.resource.class}"
        end

        StatusDB.barrier {
          @svc.update_status(Service::STATUS_RELOADING)
        }

	@svc.resource.reload(@svc, self)

        StatusDB.barrier {
          @svc.update_status(Service::STATUS_RUNNING)
        }
      end

      def on_failed
        StatusDB.barrier {
          @svc.update_status(Service::STATUS_FAIL)
        }
      end
      
    end
  end
end
