
module Dcmgr
  module PhysicalHostScheduler
    # This is a simple host scheduler which gets back a host found
    # at the top of hosts list.
    class FindLast
      def assign_to_instance(hosts, instance)
        Dcmgr::logger.debug "assign to instance (%d hosts)" % hosts.length
p 'hosts'
p hosts
        return hosts.last
        raise NoPhysicalHostError.new("can't assign physical host")
      end
    end
  end
end
