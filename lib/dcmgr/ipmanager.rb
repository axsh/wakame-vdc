# -*- coding: utf-8 -*-

module Dcmgr
  module IPManager
    extend self

    class NoAssignIPError < StandardError; end

    @check_assigned = @default_check_assigned = lambda{|ip|
      ip.instance.nil?
    }
    
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
        ip = group.ips.find{|i| assigned?(i)} or
          raise NoAssignIPError
        {:group_name=>group.name,
          :group=>group,
          :ip=>ip.ip,
          :mac=>ip.mac}
      }
    end
    
    private

    def assigned?(ip)
      @check_assigned.call(ip)
    end
  end
end
