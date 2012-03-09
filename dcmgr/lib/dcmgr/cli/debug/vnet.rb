# -*- coding: utf-8 -*-

require 'ipaddress'
require 'json'

module Dcmgr::Cli::Debug

  class Vnet < Base
    namespace :vnet
    M=Dcmgr::Models

    desc "networks", "Get networks"
    def networks
      networks_map = rpc.request('hva-collector', 'get_networks')
      Error.raise("Failed to retrieve networks.", 100) if networks_map.nil?

      print_result networks_map
    end

    desc "edges", "Get running network edges"
    def edges
      print_result broadcast.publish('debug/vnet', 'switch_info', expected_host_nodes)
    end

    desc "tunnels", "Get tunnels"
    def tunnels
      print_result broadcast.publish('debug/vnet', 'tunnels', expected_host_nodes)
    end

  end
end
