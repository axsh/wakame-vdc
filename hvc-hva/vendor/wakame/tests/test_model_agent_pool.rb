
$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'setup_master.rb'

require 'test/unit'

Wakame.config.status_db_dsn = 'sqlite:/'
Wakame::Initializer.run(:setup_database)

require 'wakame/models/agent_pool'

class TestModelAgentPool < Test::Unit::TestCase
  include Wakame::Models

  def test_pool
    AgentPool.instance
    AgentPool.instance.reset
  end
end
