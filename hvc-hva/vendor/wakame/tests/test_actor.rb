
$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_agent.rb'

require 'rubygems'

require 'test/unit'

require 'wakame'
require 'wakame/packets'
require 'wakame/agent'
require 'wakame/actor'
require 'wakame/actor/service_monitor'

class TestActor < Test::Unit::TestCase
  include Wakame


  def test_actor_registry
    reg = ActorRegistry.new
    reg.register(Actor::ServiceMonitor.new)
    assert(reg.actors.keys.include?('/wakame/actor/service_monitor'))
    reg.unregister('/wakame/actor/service_monitor')
    assert(reg.actors.size == 0)
  end

  def test_service_monitor
    require 'wakame/monitor/service'

    EM.run {
      agent = DummyAgent.new { |me|
        me.actor_registry = ActorRegistry.new
        me.monitor_registry = MonitorRegistry.new
        mon = Wakame::Monitor::Service.new
        mon.agent = me
        me.monitor_registry.register(mon, '/service')
      }

      d = Dispatcher.new(agent)
      svcmon = Actor::ServiceMonitor.new
      svcmon.agent = agent

      agent.actor_registry.register(svcmon, '/service_monitor')
      d.handle_request({:path=>'/service_monitor/register', :args=>['aaaa', 'ls -l /tmp']})
      EM.next_tick {
        assert(agent.monitor_registry.find_monitor('/service').checkers.keys.include?('aaaa'))
        EM.stop
      }
    }
  end

end
