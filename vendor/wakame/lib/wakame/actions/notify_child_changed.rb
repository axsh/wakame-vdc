module Wakame
  module Actions
    class NotifyChildChanged < Action
      def initialize(svc)
        @child_svc = svc
      end
      
      def run
        parents = StatusDB.barrier {
          parents = @child_svc.parent_instances
        }

        acquire_lock(parents.map{|c| c.resource.class.to_s }.uniq)
        
        Wakame.log.debug("#{self.class}: Parent nodes for #{@child_svc.resource.class}: " + parents.map{|c| c.resource.class }.uniq.inspect )

        parents.each { |svc|
          if svc.monitor_status != Service::STATUS_ONLINE
            next
          end

          trigger_action { |proc_action|
            svc.resource.on_child_changed(svc, proc_action)
          }
        }
        flush_subactions

      end
    end
  end
end
