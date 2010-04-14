
$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_master.rb'

require 'eventmachine'

require 'test/unit'
require 'wakame'

#WAKAME_ROOT="#{File.dirname(__FILE__)}/.."

Wakame::EventDispatcher

class TestRuleEngine < Test::Unit::TestCase
  
  class Action1 < Wakame::Action
    def run
      trigger_action(Action2.new)
      flush_subactions
    end
  end
  class Action2 < Wakame::Action
    def run
      100.times { 
        act3 = Action3.new
        trigger_action(act3)
      }
      flush_subactions
    end
  end
  class Action3 < Wakame::Action
    def run
      puts "sleeping(2)..."
      sleep (0.2 + rand(5))
    end
  end

  def test_nested_actions
    EM.run {
      manager = Wakame::ActionManager.new

      job_id = manager.trigger_action(Action1.new)

      EM.add_periodic_timer(1) {
        EM.stop if manager.active_jobs[job_id] == nil
      }
    }
  end


  class Action4 < Wakame::Action
    def run
      trigger_action(Action1.new)

      trigger_action(FailAction1.new)

      flush_subactions
    end
  end

  class FailAction1 < Wakame::Action
    def run
      trigger_action(Action1.new)
      raise StandardError
    end
  end

  def test_exception_escalation
    EM.run {
      manager = Wakame::ActionManager.new

      job_id = manager.trigger_action(Action4.new)
      EM.add_timer(10) { EM.stop }
    }
  end


  def test_each_subaction
    EM.run {
      manager = Wakame::ActionManager.new
      engine.register_rule(Rule1.new)
      EM.add_timer(1) {
      engine.active_jobs.each { |k, v|
        v[:root_action].walk_subactions {|a|
          puts a
        }
      }

      }
      EM.add_timer(5) { EM.stop }
    }
  end


  def test_cancel_action
    EM.run {
      manager = Wakame::ActionManager.new

      job_id = manager.trigger_action(Action1.new)
      EM.add_timer(1){
        manager.cancel_action(job_id) 
      }
      EM.add_timer(5) { EM.stop }
    }
  end



end
