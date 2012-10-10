# -*- coding: utf-8 -*-

require 'isono'

module Ext

  class BroadcastChannel
    def initialize(node)
      @event = Isono::NodeModules::EventChannel.new(node)
    end

    def subscribe(endpoint, &blk)
      @event.subscribe("broadcast/#{endpoint}", '#') do |args|
        handle = { :endpoint => endpoint, :command => args[0], :sender => args[1] }
        blk.call(handle, args[2])
      end
    end

    def publish(endpoint, command, expected = nil, &blk)
      context = GatherContext.new(endpoint, command)

      if blk
        # r = blk.call(context)
        # context = r if r.is_a?(GatherContext)
        # send_broadcast(context)
        # context
      else
        context = context.synchronize
        send_broadcast(context)
        context.wait(expected)
      end
    end

    def cleanup(context)
      context.timeout_timer.cancel unless context.timeout_timer.nil?
      @event.unsubscribe("gather/#{context.endpoint}", context.ticket)
    end

    def reply(handle, args)
      @event.publish("gather/#{handle[:endpoint]}", { :sender => handle[:sender], :args => [handle[:command], @event.node.node_id, args] })
    end

    private
    def send_broadcast(context)
      raise TypeError if !context.is_a?(GatherContext)
      raise "Gather context seems to be sent already: #{context.state}" if context.state != :init

      @event.subscribe("gather/#{context.endpoint}", context.ticket) do |args|
        raise("Invalid gather event args: #{args.inspect}") unless args.size == 3 && args[0] == context.command
        context.success_node_cb.call(args[1], args[2])
      end

      @event.publish("broadcast/#{context.endpoint}", :args => [context.command, context.ticket, {}])

      context.timeout_sec = 5.0 if context.timeout_sec == -1.0

      if context.timeout_sec != 0.0
        context.timeout_timer = EM::Timer.new(context.timeout_sec) { context.timeout_cb.call }
      end
    end

    class GatherContext < OpenStruct
      # They are not to be appeared in @table so that won't be inspect().
      # attr_reader :error_cb, :success_cb, :progress_cb
      attr_reader :success_node_cb, :timeout_cb
      attr_reader :state
      attr_accessor :timeout_timer

      def initialize(endpoint, command)
        super({:gather=>{
                  :endpoint=> endpoint,
                  :command => command,
                  # :args => args,
                },
                :ticket => Isono::Util.gen_id,
                :timeout_sec => -1.0,
                :sent_at => nil,
                :completed_at => nil,
                :complete_status => nil,
              })

        @success_cb = nil
        @state = :init
      end

      def endpoint
        self.gather[:endpoint]
      end

      def command
        self.gather[:command]
      end

      def on_success_node(&blk)
        raise ArgumentError unless blk
        @success_node_cb = blk
      end

      def on_timeout(&blk)
        raise ArgumentError unless blk
        @timeout_cb = blk
      end

      def synchronize
        self.extend GatherSynchronize
        self
      end

      module GatherSynchronize
        def self.extended(mod)
          raise TypeError, "This module is applicable only for GatherSynchronize" unless mod.is_a?(GatherSynchronize)
          # overwrite callbacks
          mod.instance_eval {
            @q = ::Queue.new

            on_success_node { |node,result| @q << [:success, node, result] }
            on_timeout { @q << [:timeout] }
          }
        end

        public
        def wait(expected)
          raise "response was received already." if state == :done
          raise "wait() has to be called at outside of the EventMachine's main loop." if EventMachine.reactor_thread?

          results = {}
          non_blocking = false

          while !@q.empty? || (!non_blocking && !expected.empty?)
            res = @q.deq(non_blocking)

            case res[0]
            when :success
              expected.delete(res[1])
              results[res[1]] = res[2]
            when :timeout
              non_blocking = true
            end
          end

          cleanup
          expected.each { |node| results[node] = nil }
          results
        end
      end

    end
  end

end
