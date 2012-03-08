# -*- coding: utf-8 -*-

require 'isono'

module Ext

  class BroadcastChannel
    def initialize(node)
      @event = Isono::NodeModules::EventChannel.new(node)
    end

    def subscribe(bcname, &blk)
      @event.subscribe("broadcast/#{bcname}", '#') do |args|
        handle = { :bcname => bcname, :key => args[0], :sender => args[1] }
        blk.call(handle, args[2])
      end
    end

    def publish(bcname, key, expected_nodes, &result_blk)
      queue = Queue.new
      request_id = Isono::Util.gen_id

      @event.subscribe("gather/#{bcname}", request_id) do |args|
        raise("Invalid gather args: #{args.inspect}") unless args.size == 3 && args[0] == key
        queue << [:success, args[1], args[2]]
      end

      @event.publish("broadcast/#{bcname}", :args => [key, request_id, {}])
      timeout_timer = EM::Timer.new(5) { queue << [:timeout] }

      results = {}
      non_blocking = false

      while !queue.empty? || (!non_blocking && !expected_nodes.empty?)
        res = queue.deq(non_blocking)

        case res[0]
        when :success
          expected_nodes.delete(res[1])
          results[res[1]] = res[2]
        when :timeout
          non_blocking = true
        end
      end

      timeout_timer.cancel
      @event.unsubscribe("gather/#{bcname}", request_id)

      # Make this a default action?
      expected_nodes.each { |node| results[node] = nil }
      result_blk.call(results)
    end

    def reply(handle, args)
      @event.publish("gather/#{handle[:bcname]}", { :sender => handle[:sender], :args => [handle[:key], @event.node.node_id, args] })
    end
  end

end
