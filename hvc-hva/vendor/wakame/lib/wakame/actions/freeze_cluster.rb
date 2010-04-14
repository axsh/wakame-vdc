module Wakame
  module Actions
    class FreezeCluster < Action

      def run
        acquire_lock(cluster.resources.keys.map {|resid| Service::Resource.find(resid).class.to_s  })

        StatusDB.barrier {
          cluster.update_freeze_status(Service::ServiceCluster::STATUS_UNFROZEN)
        }

      end
    end
  end
end
