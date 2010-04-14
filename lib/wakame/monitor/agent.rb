
class Wakame::Monitor::Agent
  include Wakame::Monitor
  
  def initialize
    @status = STATUS_ONLINE
  end

  def send_ping(hash)
    publish_to('ping', Wakame::Packets::Ping.new(agent, hash[:attrs], hash[:actors], hash[:monitors], hash[:services]).marshal)
  end

  def reload(config)
    # Send the first ping signal as soon as possible since the ping contanins vital information to construct the Agent object on master node.
    send_ping(check())

    if @timer && @time.running?
      @timer.stop
    end

    # Setup periodical ping publisher.
    @timer = CheckerTimer.new(config[:interval] || 10) {
      send_ping(check())
    }
    @timer.start
  end

  def check
    if Wakame.config.environment == :EC2
      attrs = Wakame::Agent.ec2_fetch_local_attrs
    else
      attrs = {}
    end

    res = {:attrs=>attrs, :monitors=>[], :actors=>[], :services=>{}}
    EM.barrier {
      agent.monitor_manager.monitors.each { |key, m|
        res[:monitors] << {:class=>m.class.to_s}
      }
      agent.actor_manager.actors.each { |key, a|
        res[:actors] << {:class=>a.class.to_s}
      }

      svcmon = agent.monitor_manager.find_monitor('/service')
      svcmon.checkers.each { |svc_id, a|
        res[:services][svc_id]={:status=>a.status}
      }
    }

    res
  end
end
