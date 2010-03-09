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
    
    # return format
    # Array, element is Hash.
    # Hash has group_name, ip, mac.
    def assign_ips
      IpGroup.map{|group|
        ip = group.ips.find{|i| assigned?(i.ip, i.mac)} or
          raise NoAssignIPError, "ip size = #{@ip_map.length}"
        {:group_name=>group.name,
          :ip=>ip.ip,
          :mac=>ip.mac}
      }
    end
    
    private

    def assigned?(mac, ip)
      @check_assigned.call(mac, ip)
    end
  end
end
