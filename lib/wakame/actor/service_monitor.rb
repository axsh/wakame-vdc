
class Wakame::Actor::ServiceMonitor
  include Wakame::Actor

  # Immediate status check for the specified Service ID.
  def check_status(svc_id)
    self.return_value = EM.barrier {
      svcmon = agent.monitor_registry.find_monitor('/service')
      svcmon.check_status(svc_id)
    }
    self.return_value
  end

end
