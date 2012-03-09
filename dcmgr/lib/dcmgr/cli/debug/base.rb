# -*- coding: utf-8 -*-

module Dcmgr::Cli::Debug

  class Base < Dcmgr::Cli::Base
    protected

    def expected_host_nodes
      expected = rpc.request('hva-collector', 'get_host_nodes_index')
      Error.raise("Failed to retrieve host_nodes.", 100) if expected.nil?

      @@expected_host_nodes = expected.map { |node| "hva.#{node[/^hn-(.+)$/, 1]}" }
    end

    def print_result(result)
      puts "result: json"
      puts JSON.pretty_generate(result)
    end

    def rpc
      @@rpc
    end

    def self.set_rpc(rpc_object)
      @@rpc = rpc_object
    end

    def broadcast
      @@broadcast
    end

    def self.set_broadcast(channel)
      @@broadcast = channel
    end

  end
end
