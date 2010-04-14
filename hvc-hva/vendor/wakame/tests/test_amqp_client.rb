#!/usr/bin/ruby

$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'

require 'test/unit'
require 'eventmachine'
require 'wakame/amqp_client'

class TestAMQPClient < Test::Unit::TestCase

  def setup
    puts "Start #{@method_name}"


  end
  
  def teardown
    puts "End #{@method_name}"
  end


  class TestClient
    include Wakame::AMQPClient

    define_exchange('ex1', :direct)
    define_exchange('ex2')
    define_exchange('ex3')

    def initialize
      super
      connect

    end
  end


  class TestClientRecv
    include Wakame::AMQPClient

    define_queue('recv1', 'ex1', {:exclusive=>true})
    define_queue('recv2', 'ex2', {:exclusive=>true})

    def initialize
      super
      connect

      add_subscriber('recv1') { |data|
        puts "From recv1 queue : #{data}"
      }
      add_subscriber('recv2') { |data|
        puts "From recv2 queue : #{data}"
      }
    end
  end


  def test_stop
    5.times {
      EM.run{
        TestClient.stop
      }
    }
    5.times {
      EM.run{
        TestClient.start
        assert_equal(TestClient, TestClient.start.class) # Get cached instance returned
        EM.next_tick { TestClient.stop }
      }
    }
  end


  def test_publish_to
    EM.run{
      TestClientRecv.start
      c = TestClient.start
      EM.next_tick {
        c.publish_to('ex2', 'aaa')

        EM.add_periodic_timer(1) {
          c.publish_to('ex1', 'test message')
        }

        EM.add_timer(10) {
          TestClientRecv.stop
          TestClient.stop
        }
      }
    }
  end

end

