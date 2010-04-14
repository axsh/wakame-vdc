module Wakame
  module Triggers
    class ShutdownUnusedVM < Trigger
      def register_hooks(cluster_id)
        event_subscribe(Event::AgentPong) { |event|
          if event.agent.services.empty? &&
              Time.now - event.agent.last_service_assigned_at > Wakame.config.unused_vm_live_period &&
              event.agent.agent_id != master.attr[:instance_id]
            Wakame.log.info("Shutting the unused VM down: #{event.agent.agent.id}")
            trigger_action(ShutdownVM.new(event.agent))
          end
        }
      end
    end
  end
end
