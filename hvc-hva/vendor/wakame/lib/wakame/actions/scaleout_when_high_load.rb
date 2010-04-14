module Wakame
  module Triggers
    class ScaleoutWhenHighLoad < Trigger
      def initialize
      end
      
      def register_hooks
        event_subscribe(LoadHistoryMonitor::AgentLoadHighEvent) { |event|
          if service_cluster.status != Service::ServiceCluster::STATUS_ONLINE
            Wakame.log.info("Service Cluster is not online yet. Skip to scaling out")
            next
          end
          Wakame.log.debug("Got load high avg: #{event.agent.agent_id}")

          propagate_svc = nil
          event.agent.services.each { |id, svc|
            if svc.property.class == Service::Apache_APP
              propagate_svc = svc 
              break
            end
          }

          unless propagate_svc.nil?
            trigger_action(Actions::PropagateInstancesAction.new(propagate_svc.property)) 
          end
        }

        event_subscribe(LoadHistoryMonitor::AgentLoadNormalEvent) { |event|
          next

          if service_cluster.status != Service::ServiceCluster::STATUS_ONLINE
            Wakame.log.info("Service Cluster is not online yet.")
            next
          end
          Wakame.log.debug("Back to normal load: #{event.agent.agent_id}")
          event.agent.services.each { |id, svc|
            trigger_action(Actions::StopService.new(svc))
          }
          
        }
      end
    end
  end
end
