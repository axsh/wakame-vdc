module Wakame
  class Trigger
    include FilterChain
    include AttributeHelper

    def_attribute :enabled, true

    #def service_cluster
    #  action_manager.service_cluster
    #end
    #alias :cluster :service_cluster

    def master
      Master.instance
    end

    def agent_monitor
      master.agent_monitor
    end

    def command_queue
      master.command_queue
    end

    def trigger_action(action)
      job_id = master.action_manager.trigger_action(action)
    end

    def register_hooks(service_cluster_id)
    end

    def cleanup
    end

    protected
    def event_subscribe(event_class, &blk)
      EventDispatcher.subscribe(event_class) { |event|
        begin
          run_filter(self)
          blk.call(event) if self.enabled 
        rescue => e
          Wakame.log.error(e)
        end
      }
    end

  end

end
