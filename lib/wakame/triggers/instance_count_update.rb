module Wakame
  module Triggers
    class InstanceCountUpdate < Trigger
      append_filter { |rule|
        rule.service_cluster.status == Service::ServiceCluster::STATUS_ONLINE
      }

      def register_hooks(cluster_id)
        @instance_counters = {}
        ms = Scheduler::PerHourSequence.new
        #ms[0]=1
        #ms[30]=5
        ms[0]=1
        ms["0:2:00"]=4
        ms["0:5:00"]=1
        ms["0:9:00"]=4
        ms["0:13:00"]=1
        ms["0:17:00"]=4
        ms["0:21:00"]=1
        ms["0:25:00"]=1
        ms["0:29:00"]=1
        ms["0:33:00"]=4
        #ms["0:37:00"]=1
        #ms["0:41:00"]=4
        ms["0:45:00"]=1
        ms["0:49:00"]=4
        ms["0:53:00"]=1
        ms["0:57:00"]=4
        # @instance_counters[Apache_APP.to_s] = TimedCounter.new(Scheduler::LoopSequence.new(ms), self)

        event_subscribe(Event::InstanceCountChanged) { |event|
          next if service_cluster.status == Service::ServiceCluster::STATUS_OFFLINE

          if event.increased?
            Wakame.log.debug("#{self.class}: trigger PropagateInstancesAction.new(#{event.resource.class})")
            trigger_action(Actions::PropagateInstancesAction.new(event.resource))
          elsif event.decreased?
            Wakame.log.debug("#{self.class}: trigger DestroyInstancesAction.new(#{event.resource.class})")
            trigger_action(Actions::DestroyInstancesAction.new(event.resource))
          end
        }
      end
    end
  end
end
