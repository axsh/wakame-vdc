# -*- coding: utf-8 -*-

module Dcmgr::Cli::Debug

  class Base < Dcmgr::Cli::Base
    protected

    def debug_gather(debug_type, expected_ids, &result_blk)
      queue = Queue.new
      request_id = Isono::Util.gen_id

      event.subscribe('gather/debug/vnet', request_id) do |args|
        next unless args.size == 3 && args[0] == debug_type
        queue << [:success, args[1], args[2]]
      end

      event.publish('broadcast/debug/vnet', :args => [debug_type, request_id, {}])
      timeout_timer = EM::Timer.new(5) { queue << [:timeout, {}] }

      results = {}
      non_blocking = false

      while !queue.empty? || (!non_blocking && !expected_ids.empty?)
        res = queue.deq(non_blocking)

        case res[0]
        when :success
          expected_ids.delete(res[1])
          results[res[1]] = res[2]
        when :timeout
          non_blocking = true
        end
      end

      timeout_timer.cancel
      event.unsubscribe('gather/debug/vnet', request_id)

      expected_ids.each { |node| results[node] = nil }
      result_blk.call(results)
    end

    def rpc
      @@rpc
    end

    def self.set_rpc(rpc_object)
      @@rpc = rpc_object
    end

    def event
      @@event
    end

    def self.set_event(event_object)
      @@event = event_object
    end

  end
end
