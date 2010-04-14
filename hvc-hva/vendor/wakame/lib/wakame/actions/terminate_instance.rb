module Wakame
  module Actions
    class TerminateInstance < Action
      def initialize(options)
        @options = options
      end

      def run
        p @options
        active_agents = []
        StatusDB.barrier{
          active_agents = Models::AgentPool.group_active
        }
        agent_id = active_agents.select {|agent|
          local_ip = agent.split('-')
          @options["hva_ip"] == local_ip[0]
        }
        agent_id.each{|agent_id|
          trigger_action{|action|
            action.actor_request(agent_id, '/xen/terminate_instance', @options){|req|
              req.wait
              Wakame.log.debug("VM Terminated")
            }
          }
          flush_subactions
          instance = Models::Instance.find(@options["instance_uuid"])
          instance.status = 0
          instance.save        
        }
      end
    end
  end
end
