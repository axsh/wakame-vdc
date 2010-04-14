module Wakame
  module Actions
    class PropagateResource < Action

      def initialize(resource, cloud_host_id)
        raise ArgumentError unless resource.is_a?(Wakame::Service::Resource)
        @resource = resource
        @cloud_host_id = cloud_host_id
      end

      def run
        acquire_lock(@resource.class.to_s)

        newsvc=nil
        StatusDB.barrier {
          newsvc = service_cluster.propagate_resource(@resource, @cloud_host_id)
        }

        trigger_action(StartService.new(newsvc))
        flush_subactions
      end

    end
  end
end
