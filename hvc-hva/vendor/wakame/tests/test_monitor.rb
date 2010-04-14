
$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_agent.rb'

require 'rubygems'

require 'test/unit'

require 'wakame'
require 'wakame/packets'
require 'wakame/monitor'
require 'wakame/monitor/agent'
require 'wakame/monitor/service'

class TestMonitor < Test::Unit::TestCase
  include Wakame

  def test_agent_monitor
    EM.run {
      agent = DummyAgent.new
      a = Monitor::Agent.new(agent)
      a.setup
      a.check

      EM.add_timer(21) { 
        assert_equal(2, agent.publish_count)
        EM.stop
      }
    }
  end

  def test_checker_timer
    EM.run {
      count = 0
      timer = Monitor::CheckerTimer.new(1) {
        count += 1
        puts "a"
      }

      timer.start 
      EM.add_timer(5) { puts count; assert((4..5).include?(count) );  EM.stop}
    }
  end

end
