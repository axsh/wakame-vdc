# -*- coding: utf-8 -*-

module Dcmgr
  module IP_MANAGER
    class NoAssignIPError < StandardError; end

    @check_assigned = @default_check_assigned = lambda{|mac, ip|
      Instance.filter(:ip => ip).count <= 0
    }
    
    extend self
    def setup(ip_map)
      # {'MAC_ADDR_A' => '192.168.1.x',
      #  'MAC_ADDR_B' => '192.168.1.y', ...}
      @ip_map = ip_map
    end

    def macaddress_by_ip(ip)
      matched = @ip_map.find{|mac_adr, ip_adr|
        ip_adr == ip
      }
      return nil unless matched
      matched[0]
    end

    def set_assigned?(&block)
      @check_assigned = block
    end

    def set_default_assigned?
      @check_assigned = @default_check_assigned
    end
    
    # return [mac_address, ip_address]
    def assign_ip
      @ip_map.find{|mac, ip| assigned?(mac, ip)} or raise NoAssignIPError, "ip size = #{@ip_map.length}"
    end
    
    private

    def assigned?(mac, ip)
      @check_assigned.call(mac, ip)
    end
  end
end
