#!/usr/bin/ruby

$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_master.rb'

require 'wakame'
require 'wakame/service'
require 'wakame/queue_declare'

class TestMaster < Test::Unit::TestCase

  def setup
    puts "Start #{@method_name}"
  end
  
  def teardown
    puts "End #{@method_name}"
  end

  def test_master_stop
    5.times {
      EM.run{
        Wakame::Master.stop
      }
    }
    5.times {
      EM.run{
        Wakame::Master.start
        EM.add_timer(1) { Wakame::Master.stop }
      }
    }
  end

  def test_command_queue
  end

  def test_service_cluster
  end


  class MockAgent
    def initialize
      # Do nothing
    end

    def agent_id
      'asdfasdfasdfasdfasdf'
    end
    def agent_ip
      '127.0.0.1'
    end
  end


  class DummyResponder2
    include Wakame::AMQPClient
    include Wakame::QueueDeclare

    AGENT_ID='__standalone__'

    def self.create_register_hash()
      {:agent_id=>AGENT_ID, :responded_at=>Time.now.to_s, :type=>Wakame::Packets::Register.to_s}
    end
    def self.create_unregister_hash()
      {:agent_id=>AGENT_ID, :responded_at=>Time.now.to_s, :type=>Wakame::Packets::UnRegister.to_s}
    end
    def self.create_ping_hash()
      {:agent_id=>AGENT_ID, :responded_at=>Time.now.to_s, :type=>Wakame::Packets::Ping.to_s, :attrs=>{}, :monitors=>{}, :actors=>{}, :services=>{}}
    end

    define_queue 'agent_actor.%{agent_id}', 'agent_command', {:key=>'agent_id.%{agent_id}', :auto_delete=>true}

    def agent_id
      AGENT_ID
    end

    def initialize()
      connect

      add_subscriber("agent_actor.#{agent_id}") { |data|
        data = eval(data)
        p data

        if data[:path] == '/test/echo'
          sleep 5
          publish_to('agent_event', Wakame::Packets::ActorResponse.new(self, data[:token], Wakame::Actor::STATUS_SUCCESS).marshal)
        end
      }
    end
    
    def test_registered_agent
      self.publish_to('registry', self.class.create_register_hash.inspect)
      EM.add_periodic_timer(1) {
        self.publish_to('ping', self.class.create_ping_hash.inspect)
      }
    end

    def test_unregistered_agent
      EM.add_periodic_timer(1) {
        self.publish_to('ping', self.class.create_ping_hash.inspect)
      }
    end

  end


  def test_agent_monitor
    flag_statchanged=false
    flag_monitored=false

    EM.run {
      master = Wakame::Master.start
      dr2 = DummyResponder2.start

      dr2.test_registered_agent

      EM.next_tick {
        Wakame::ED.subscribe(Wakame::Event::AgentStatusChanged) { |event|
          flag_statchanged = true
        }
        Wakame::ED.subscribe(Wakame::Event::AgentMonitored) { |event|
          flag_monitored = true
        }
        
        Wakame::ED.subscribe(Wakame::Event::AgentPong) { |event|
          puts "#{event.class.to_s} has been received from #{event.agent.agent_id}"
          assert_equal(1, master.agent_monitor.registered_agents.size)
          assert_equal(0, master.agent_monitor.unregistered_agents.size)
          
          EM.add_timer(1) {
            Wakame::Master.stop
            DummyResponder2.stop
          }
        }
      }
      
    }

    assert(flag_monitored)
    assert(flag_statchanged)
  end



  def test_actor_request
    EM.run {
      master = Wakame::Master.start
      dr2 = DummyResponder2.start

      dr2.test_registered_agent

      EM.next_tick {
        req = master.actor_request('__standalone__', '/test/echo', 'a', 'b', 'c').request
        EM.defer proc {
          req.wait_completion
        }, proc {
          EM.stop
        }
      }
    }
  end
  
end
