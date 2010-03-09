# -*- coding: utf-8 -*-

module Dcmgr
  module IPManager
    extend self

    class NoAssignIPError < StandardError; end

    @check_assigned = @default_check_assigned = lambda{|mac, ip|
      Instance.filter(:ip => ip).count <= 0
    }
    
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
    def assign_ips
      @ip_map.find{|mac, ip| assigned?(mac, ip)} or
        raise NoAssignIPError, "ip size = #{@ip_map.length}"
    end
    
    private

    def assigned?(mac, ip)
      @check_assigned.call(mac, ip)
    end
  end
end
