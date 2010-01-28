# -*- coding: utf-8 -*-

module Dcmgr
  module IP_MANAGER
    class NoAssignIPError < StandardError; end
    
    extend self
    def setup(ip_map)
      # {'MAC_ADDR_A' => '192.168.1.x',
      #  'MAC_ADDR_B' => '192.168.1.y', ...}
      @ip_map = ip_map
    end

    def set_assigned?(&block)
      @check_assigned = block
    end
    
    # return [mac_address, ip_address]
    def assign_ip
      @ip_map.find{|mac, ip| assigned?(mac, ip)} or raise NoAssignIPError
    end
    
    private

    def assigned?(mac, ip)
      @check_assigned.call(mac, ip)
    end
  end
end
