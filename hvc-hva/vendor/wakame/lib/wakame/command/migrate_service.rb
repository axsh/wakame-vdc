
class Wakame::Command::MigrateService
  include Wakame::Command

  def run
    svc = nil
    svc = service_cluster.find_service(options["service_id"])
    if svc.nil?
      raise "Unknown Service ID: #{options["service_id"]}" 
    end

    # Optional destination agent 
    agent = nil
    if options["agent_id"]
      agent = master.agent_monitor.agent_pool.find_agent(options["agent_id"])
      if agent.nil?
        raise "Unknown Agent ID: #{options["agent_id"]}" 
      end
    end

    trigger_action(Wakame::Actions::MigrateService.new(svc, agent))
  end

end
