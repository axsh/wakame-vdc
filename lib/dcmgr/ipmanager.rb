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
    def assign_ips(instance=nil)
      Dcmgr.db.transaction do
        ips = IpGroup.map{|group|
          ip = group.ips.find{|i| assigned?(i)} or
          raise NoAssignIPError
          
          {:group_name=>group.name,
            :group=>group,
            :ip=>ip}
        }.tap{|ips|
          assigin_ips_to(instance, ips) if instance
        }
      end
    end
    
    private

    def assigin_ips_to(instance, ips)
      ips.each{|ip|
        ip_obj = ip[:ip]
        ip_obj.instance = instance
        ip_obj.save
      }
    end

    def assigned?(ip)
      @check_assigned.call(ip)
    end
  end
end
