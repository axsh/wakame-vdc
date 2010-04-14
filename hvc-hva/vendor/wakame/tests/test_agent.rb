#!/usr/bin/ruby

$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_agent.rb'

require 'rubygems'
require 'test/unit'

require 'wakame'
require 'wakame/agent'

class TestAgent < Test::Unit::TestCase

  def setup
    puts "Start #{@method_name}"
  end
  
  def teardown
    puts "End #{@method_name}"
  end

  def test_agent_stop
    5.times {
      EM.run{
        Wakame::Agent.stop
      }
    }
    5.times {
      EM.run{
        Wakame::Agent.start
        assert_equal(Wakame::Agent, Wakame::Agent.start.class) # Get cached instance returned
        EM.add_timer(1) { Wakame::Agent.stop }
      }
    }
  end

  DUMMY_INSTANCE_ID='dummy_instance_id'
  class DummyService < Wakame::Service::Property
    attr_reader :check_count
    def initialize(check_time=0.3)
      super(check_time)
      @check_count = 0
    end

    def start
      @start_time ||= Time.now
      #log.debug "/etc/init.d/apache start"
      puts "/etc/init.d/apache start"
      sleep 2
    end

    def check
      return false if @start_time.nil?
      @check_count += 1
      #log.debug "checking... #{Time.now - @start_time} : #{Thread.current.inspect}"
      puts "checking... #{Time.now - @start_time} : #{Thread.current.inspect}"

      sleep 0.5

      return Time.now - @start_time > 4.5 ? true : false
    end

    def stop
      #log.debug "/etc/init.d/apache stop"
      puts "/etc/init.d/apache stop"
      @start_time = nil
      sleep 2
    end
  end

  ## This test dies when the test ran after another test.
  # The test process stops at sleep() in DummyService#check(). The hang seems to be occured in EM's C backend though check() method runs in EM.defer thread which is Ruby thread.
  def test_service_monitor
    status_changed_flag=0
    Wakame::EH.reset
    EM.run {
      monitor = Wakame::ServiceMonitor.new
      Wakame::EH.subscribe(Wakame::Event::ServiceStatusChanged) { |event|
        assert_equal(DUMMY_INSTANCE_ID, event.instance_id)
        status_changed_flag=1
      }
      dummy = Wakame::ServiceRunner.new(DUMMY_INSTANCE_ID, DummyService.new(2))
      monitor.register(dummy)

      Wakame::EH.subscribe(Wakame::Event::ServiceOnline) { |event|

        count = 0
        monitor.monitors {|i|
          count+=1
        }

        assert(dummy.property.check_count > 0)
        assert_equal(1, count)
        assert_equal(DUMMY_INSTANCE_ID, event.instance_id)
        EM.next_tick {
          EM.stop
        }
      }

      
      EM.defer proc { dummy.start }
      # Do not use EM.next_tick{ sleep 5 }. This holds EM's main thread up. 
      # Run DummyService#check() for 5 secs
    }
  end


  def test_send_cmd
    EM.run {
      agent = Wakame::Agent.start
      EM.next_tick {
        agent.send_cmd(Wakame::Packets::Agent::Nop.new)
        Wakame::Agent.stop
      }
    }
  end


  class DummyMaster
    include Wakame::AMQPClient
    include Wakame::QueueDeclare
    
    define_queue 'registry', 'registry'
    define_queue 'ping', 'ping'
    define_queue 'agent_event', 'agent_event'

    def initialize()
      connect()
      @counters = {'registry'=>0,'ping'=>0,'agent_event'=>0, }
      add_subscriber('registry') { |data|
        p data
        @counters['registry'] += 1
      }

      add_subscriber('ping') { |data|
        p data
        @counters['ping'] += 1
      }

      add_subscriber('agent_event') { |data|
        p data
        @counters['agent_event'] += 1
      }
    end

    def debug_counters
      @counters
    end


    def send_actor_request(agent_id, path, *args)
      publish_to('agent_command', "agent_id.#{agent_id}", Wakame::Packets::Agent::ActorRequest.new(agent_id, path, *args).marshal)
    end

    
  end

  def test_agent_monitor
    EM.run {
      DummyMaster.start
      agent = Wakame::Agent.start
      EM.add_timer(5){ EM.stop }
    }
  end


  def test_service_monitor
    EM.run {
      master = DummyMaster.start
      agent = Wakame::Agent.start

      svcmon = agent.find_monitor('/service')
      svcmon.register('aaaaa', 'ls -l /usr')
      svcmon.register('bbbbb', 'ls -l /dev')

      assert(svcmon.checkers.keys.member?('aaaaa') && svcmon.checkers.keys.member?('bbbbb'))

      EM.add_timer(8) {
        svcmon.unregister('aaaaa')
        svcmon.unregister('bbbbb')

        svcmon.register('ccc', 'ls -l /var')

        assert_equal(['ccc'], svcmon.checkers.keys)
      }

      EM.add_timer(15){ 
        assert(master.debug_counters['agent_event'] > 2)
        EM.stop
      }
    }
  end


  def test_actor
    EM.run {
      master = DummyMaster.start
      agent = Wakame::Agent.start
      EM.next_tick {
        master.send_actor_request(agent.agent_id, '/service_monitor/register', ['12345', 'pidof ls'])
        EM.add_timer(1) {
          p agent.monitor_registry.find_monitor('/service').checkers.keys
          assert_not_nil(agent.monitor_registry.find_monitor('/service').checkers['12345'])
          EM.add_timer(4.5){
            master.send_actor_request(agent.agent_id, '/service_monitor/unregister', ['12345'])
            EM.add_timer(1) {
              assert_nil(agent.monitor_registry.find_monitor('/service').checkers['12345'])
              EM.stop
            }
          }
        }
      }
    }
  end

end
