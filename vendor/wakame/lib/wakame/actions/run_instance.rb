module Wakame
  module Actions
    class RunInstance < Action
      def initialize(option)
        @options = option
      end

      def run
        p @options
        active_agents = []
        StatusDB.barrier {
          active_agents = Models::AgentPool.group_active
        }
        agent_id = active_agents.find {|a|
          local_ip = a.split('-')
          @options["hva_ip"] == local_ip[0]
        }
        p agent_id
        
        req = actor_request(agent_id, '/xen/run_instance', @options)
        req.request
        req.wait
        Wakame.log.debug("VM Launched")
        flush_subactions
        instance = Models::Instance.find(@options["instance_uuid"])
        instance.status = 2
        instance.save
      end

    end
  end
end
