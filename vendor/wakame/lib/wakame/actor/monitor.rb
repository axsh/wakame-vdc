
class Wakame::Actor::Monitor
  include Wakame::Actor

  def reload(monitor_path, config)
    mon = agent.monitor_manager.find_monitor(monitor_path) ||
      raise("#{self.class}: The monitor namespace was not found: #{monitor_path}")
    
    EM.barrier {
      mon.reload(config)
    }
  end
  
end
