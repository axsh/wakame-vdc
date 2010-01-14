#!/usr/bin/ruby

require 'rubygems'

require 'eventmachine'
require 'mq'
require 'thread'

require 'wakame'
require 'wakame/amqp_client'
require 'wakame/queue_declare'

module Wakame
  class Agent
    include AMQPClient
    include QueueDeclare

    define_queue 'agent_actor.%{agent_id}', 'agent_command', {:key=>'agent_id.%{agent_id}', :auto_delete=>true}

    attr_reader :managers, :monitor_manager, :actor_manager

    def agent_id
      @agent_id
    end

    def initialize(opts={})
      @managers = {}
      determine_agent_id
    end

    # post_setup
    def init
      @monitor_manager = register_manager(AgentManagers::MonitorManager.new)
      @actor_manager = register_manager(AgentManagers::ActorManager.new)

      @managers.values.each { |mgr|
        mgr.init
      }

      if Wakame.config.environment == :EC2
        attrs = self.class.ec2_fetch_local_attrs
      else
        attrs = {}
      end
      publish_to('registry', Packets::Register.new(self, Wakame.config.root_path.to_s, attrs).marshal)
      Wakame.log.info("Started agent process : AMQP Server=#{amqp_server_uri.to_s} WAKAME_ROOT=#{Wakame.config.root_path} WAKAME_ENV=#{Wakame.config.environment}, attrs=#{attrs.inspect}")
    end

    def cleanup
      publish_to('registry', Packets::UnRegister.new(self).marshal)
    end

    def determine_agent_id
      if Wakame.config.environment == :EC2
        @agent_id = self.class.ec2_query_metadata_uri('instance-id')
      else
        # for Linux
        @nic = 'eth0'

        cmd = (`/sbin/ifconfig #{@nic}`).split(/\n+/)
        cmd[0] =~ %r/^#{@nic}\s+Link\sencap:Ethernet\s+HWaddr\s(\S+)\s+$/m
        @macaddr = $1

        cmd[1] =~ %r/^\s+inet addr:(\d+\.\d+\.\d+\.\d+).*$/m
        abort("Failed to get ipaddress") if cmd[1].nil?
        @ipaddr = $1

        @agent_id = "#{@ipaddr}-#{@macaddr}"
        @agent_id
      end
    end

    def self.ec2_query_metadata_uri(key)
      require 'open-uri'
      open("http://169.254.169.254/2008-02-01/meta-data/#{key}") { |f|
        return f.readline
      }
    end

    def self.ec2_fetch_local_attrs
      attrs = {}
      %w[instance-id instance-type local-ipv4 local-hostname public-hostname public-ipv4 ami-id].each { |key|
        rkey = key.tr('-', '_')
        attrs[rkey.to_sym]=ec2_query_metadata_uri(key)
      }
      attrs[:availability_zone] = ec2_query_metadata_uri('placement/availability-zone')
      attrs
    end


    def register_manager(agent_mgr)
      raise ArgumentError unless agent_mgr.kind_of? Wakame::AgentManager
      agent_mgr.agent = self
      raise "The manager module is registered: #{agent_mgr.class.to_s}" if @managers.has_key? agent_mgr.class.to_s
      @managers[agent_mgr.class.to_s] = agent_mgr
      agent_mgr
    end

    def unregister_manager(agent_mgr_name)
      @managers.delete(agent_mgr_name.to_s)
    end

  end
end
