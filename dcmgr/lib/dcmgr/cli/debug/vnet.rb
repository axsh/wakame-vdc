# -*- coding: utf-8 -*-

require 'ipaddress'

module Dcmgr::Cli::Debug

  class Vnet < Base
    namespace :vnet
    M=Dcmgr::Models

    desc "networks", "Get networks"
    def networks
      networks_map = rpc.request('hva-collector', 'get_networks')
      Error.raise("Failed to retrieve networks.", 100) if networks_map.nil?

      networks_map.each { |network|
        puts "#{network[:uuid]} \t#{network[:ipv4_network]}/#{network[:prefix]}"
      }
    end

    desc "edges", "Get running network edges"
    def edges
      # Get list of host node indexes.
      expected_ids = rpc.request('hva-collector', 'get_host_nodes_index')
      Error.raise("Failed to retrieve host_nodes.", 100) if expected_ids.nil?

      expected_ids.map! { |node| "hva.#{node[/^hn-(.+)$/, 1]}" }

      results = broadcast.publish('debug/vnet', 'switch_info', expected_ids)

      results.each { |key,result|
        if !result.nil?
          puts "#{key}: \ttype:#{result[:type]}"
        else
          puts "#{key}: \terror"
        end
      }
    end

  end
end
