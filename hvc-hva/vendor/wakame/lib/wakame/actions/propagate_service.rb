module Wakame
  module Actions
    class PropagateService < Action

      def initialize(svc, cloud_host_id=nil)
        raise ArgumentError unless svc.is_a?(Wakame::Service::ServiceInstance)
        @svc = svc
        @cloud_host_id = cloud_host_id
      end


      def run
        acquire_lock(@svc.resource.class.to_s)

        newsvc = nil
        StatusDB.barrier {
          newsvc = cluster.propagate_service(@svc.id, @cloud_host_id)
        }
        trigger_action(StartService.new(newsvc))
        flush_subactions
      end

    end
  end
end
