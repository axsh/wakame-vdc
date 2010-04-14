#!/usr/bin/ruby

require 'rubygems'

require 'wakame'
require 'wakame/queue_declare'

module Wakame

   class Master
     include Wakame::AMQPClient
     include Wakame::QueueDeclare

     define_queue 'agent_event', 'agent_event'
     define_queue 'ping', 'ping'
     define_queue 'registry', 'registry'

     attr_reader :command_queue, :agent_monitor, :cluster_manager, :action_manager, :started_at
     attr_reader :managers

    def initialize(opts={})
      pre_setup
    end


    def actor_request(agent_id, path, *args)
      request = Wakame::Packets::ActorRequest.new(agent_id, Util.gen_id, path, *args)
      ActorRequest.new(self, request)
    end


    def cleanup
      @managers.each { |m| m.terminate }
      @command_queue.shutdown
    end

    def register_manager(manager)
      raise ArgumentError unless manager.kind_of? MasterManager
      manager.master = self
      @managers << manager
      manager
    end

    # post_setup
    def init
      raise 'has to be put in EM.run context' unless EM.reactor_running?
      @command_queue = register_manager(MasterManagers::CommandQueue.new)

      # WorkerThread has to run earlier than other managers.
      @agent_monitor = register_manager(MasterManagers::AgentMonitor.new)
      @cluster_manager = register_manager(MasterManagers::ClusterManager.new)
      @action_manager = register_manager(MasterManagers::ActionManager.new)

      @managers.each {|m|
        Wakame.log.debug("Initializing Manager Module: #{m.class}")
        m.init
      }

      Wakame.log.info("Started master process : AMQP Server=#{amqp_server_uri.to_s} WAKAME_ROOT=#{Wakame.config.root_path} WAKAME_ENV=#{Wakame.config.environment}")
    end


    def self.ec2_query_metadata_uri(key)
      require 'open-uri'
      open("http://169.254.169.254/2008-02-01/meta-data/#{key}"){|f|
        return f.readline
      }
    end

    def self.ec2_fetch_local_attrs
      attrs = {}
      %w[instance-id instance-type local-ipv4 local-hostname public-hostname public-ipv4 ami-id].each{|key|
        rkey = key.tr('-', '_')
        attrs[rkey.to_sym]=ec2_query_metadata_uri(key)
      }
      attrs[:availability_zone]=ec2_query_metadata_uri('placement/availability-zone')
      attrs
    end

    private
    def pre_setup
      @started_at = Time.now
      @managers = []

      StatusDB::WorkerThread.init

      StatusDB.pass {
        Wakame.log.debug("Binding thread info to EventDispatcher.")
        EventDispatcher.instance.bind_thread(Thread.current)
      }
    end


  end


  class ActorRequest
    attr_reader :master, :return_value

    def initialize(master, packet)
      raise TypeError unless packet.is_a?(Wakame::Packets::ActorRequest)

      @master = master
      @packet = packet
      @requested = false
      @event_ticket = nil
      @return_value = nil
      @wait_lock = ::Queue.new
    end


    def request
      raise "The request has already been sent." if @requested

      @event_ticket = EventDispatcher.subscribe(Event::ActorComplete) { |event|
        if event.token == @packet.token
         
          # Any of status except RUNNING are accomplishment of the actor request.
          Wakame.log.debug("#{self.class}: The actor request has been completed: token=#{self.token}, status=#{event.status}, return_value=#{event.return_value}")
          EventDispatcher.unsubscribe(@event_ticket)
          @return_value = event.return_value
          @wait_lock.enq([event.status, event.return_value])
        end
      }
      Wakame.log.debug("#{self.class}: Send the actor request: #{@packet.path}@#{@packet.agent_id}, token=#{self.token}")
      master.publish_to('agent_command', "agent_id.#{@packet.agent_id}", @packet.marshal)
      @requested = true
      self
    end


    def token
      @packet.token
    end

    def progress
      check_requested?
      raise NotImplementedError
    end

    def cancel
      check_requested?
      raise NotImplementedError
      
      #master.publish_to('agent_command', "agent_id.#{@packet.agent_id}", Wakame::Packets::ActorCancel.new(@packet.agent_id, ).marshal)
      #ED.unsubscribe(@event_ticket)
    end

    def wait_completion(tout=60*30)
      check_requested?
      timeout(tout) {
        Wakame.log.debug("#{self.class}: Waiting a response from the actor: #{@packet.path}@#{@packet.agent_id}, token=#{@packet.token}")
        ret_status, ret_val = @wait_lock.deq
        Wakame.log.debug("#{self.class}: A response (status=#{ret_status}) back from the actor: #{@packet.path}@#{@packet.agent_id}, token=#{@packet.token}")
        if ret_status == Actor::STATUS_FAILED
          raise RuntimeError, "Failed status has been returned: Actor Request #{token}"
        end
        ret_val
      }
    end
    alias :wait :wait_completion
    
    private
    def check_requested?
      raise "The request has not been sent yet." unless @requested
    end
  end
end
