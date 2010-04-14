module Wakame
  module Actions
    class NotifyParentChanged < Action
      def initialize(svc)
        @parent_svc = svc
      end
      
      def run
        children = StatusDB.barrier {
          @parent_svc.child_instances
        }

        acquire_lock(children.map{|c| c.resource.class.to_s }.uniq)
        
        Wakame.log.debug("#{self.class}: Child nodes for #{@parent_svc.resource.class}: " + children.map{|c| c.resource.class }.uniq.inspect )

        children.each { |svc|
          if svc.monitor_status != Service::STATUS_ONLINE
            next
          end

          trigger_action { |proc_action|
            svc.resource.on_parent_changed(svc, proc_action)
          }
        }
        flush_subactions

      end
    end
  end
end
