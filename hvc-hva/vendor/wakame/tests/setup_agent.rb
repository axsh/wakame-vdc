
$:.unshift File.dirname(__FILE__) + '/../lib'

WAKAME_ROOT="#{File.dirname(__FILE__)}/.."
WAKAME_FRAMEWORK_ROOT="#{File.dirname(__FILE__)}/.."
WAKAME_ENV=:StandAlone

require 'rubygems' rescue nil

require 'test/unit'

require 'wakame'
require 'wakame/initializer'

#require "#{WAKAME_ROOT}/config/boot"
#Wakame::Bootstrap.boot_agent!

Wakame::Initializer.run(:process_agent)


class DummyAgent
  attr_reader :publish_count

  attr_accessor :actor_registry, :monitor_registry

  def initialize(&blk)
    blk.call(self) if blk
    @publish_count = 0
  end
  
  def agent_id
    'test_id'
  end

  def publish_to(*args)
    @publish_count += 1
  end

end
