
module Dcmgr
  module PhysicalHostScheduler
    class NoPhysicalHostError < StandardError; end

    module Algorithm1
      def assign_to_instance(hosts, instance)
        Dcmgr::logger.debug "alrogithm 1 schedule instance--"
        raise NoPhysicalHostError.new("no enable physical hosts") if hosts.length == 0
        hosts[0]
      end
    end
    
    module Algorithm2
      def assign_to_instance(hosts, instance)
        Dcmgr::logger.debug "assign to instance (%d hosts)" % hosts.length
        Dcmgr::logger.debug " instance[#{instance}] - cpus: #{instance.need_cpus} / cpu_mhz: #{instance.need_cpu_mhz} / memory: #{instance.need_memory}"
        hosts.each{|ph|
          Dcmgr::logger.debug " #{ph} - " +
            "cpus: #{ph.cpus} / " +
            "space cpu_mhz: #{ph.space_cpu_mhz} / " +
            "space memory: #{ph.space_memory}"
          
          if instance.need_cpus <= ph.cpus and
              instance.need_cpu_mhz <= ph.space_cpu_mhz and
              instance.need_memory <= ph.space_memory
            Dcmgr::logger.debug "assign to instance: %s" % ph
            return ph
          end
        }
        
        raise NoPhysicalHostError.new("can't assign physical host")
      end
    end
  end
end
