
class Wakame::Command::AgentStatus
  include Wakame::Command

  command_name 'agent_status'

  def run(rule)
    EM.barrier {
      registered_agents = rule.agent_monitor.registered_agents[@options["agent_id"]]
      service_cluster = rule.service_cluster
      res ={
       :agent_status =>registered_agents.dump_status,
       :service_cluster =>service_cluster.dump_status
      }
      res
    }
  end
end
