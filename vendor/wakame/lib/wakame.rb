
require 'rubygems'

require 'uri'
require 'ext/uri'
# For debugging
Thread.abort_on_exception = true 

module Wakame
  require 'jeweler/version_helper'
  VERSION=Jeweler::VersionHelper.new(File.expand_path('../', File.dirname(__FILE__))).to_s

  autoload :Agent, 'wakame/agent'
  autoload :Master, 'wakame/master'
  autoload :Daemonize, 'wakame/daemonize'
  autoload :Util, 'wakame/util'
  autoload :Event, 'wakame/event'
  autoload :Service, 'wakame/service'
  autoload :Rule, 'wakame/rule'
  autoload :Graph, 'wakame/graph'
  autoload :Monitor, 'wakame/monitor'
  autoload :Actor, 'wakame/actor'
  autoload :Configuration, 'wakame/configuration'
  autoload :Logger, 'wakame/logger'
  autoload :Packets, 'wakame/packets'
  autoload :AMQPClient, 'wakame/amqp_client'
  autoload :EventDispatcher, 'wakame/event_dispatcher'
  autoload :Scheduler, 'wakame/scheduler'
  autoload :Command, 'wakame/command'
  autoload :CommandQueue, 'wakame/command_queue'
  autoload :Template, 'wakame/template'
  autoload :Trigger, 'wakame/trigger'
  autoload :Action, 'wakame/action'
  autoload :RuleEngine, 'wakame/rule_engine'
  autoload :StatusDB, 'wakame/status_db'
  autoload :ActionManager, 'wakame/action_manager'
  autoload :AgentManager, 'wakame/agent_manager'
  module AgentManagers
    autoload :MonitorManager, 'wakame/agent_managers/monitor_manager'
    autoload :ActorManager, 'wakame/agent_managers/actor_manager'
  end
  autoload :MasterManager, 'wakame/master_manager'
  module MasterManagers
    autoload :ActionManager, 'wakame/master_managers/action_manager'
    autoload :CommandQueue, 'wakame/master_managers/command_queue'
    autoload :AgentMonitor, 'wakame/master_managers/agent_monitor'
    autoload :ClusterManager, 'wakame/master_managers/cluster_manager'
  end
  #autoload :Initializer, 'wakame/initializer' # Do not autoload this class since the constant is used for the flag in bootstrap.

  def gen_id(str=nil)
    Util.gen_id(str)
  end

  def log
    Logger.log
  end

  module_function :gen_id, :log

  class << self
    def config
      Initializer.instance.configuration
    end

    def environment
      config.environment
    end

    def new_(class_or_str)
      Util.new_(class_or_str)
    end
  end

end
