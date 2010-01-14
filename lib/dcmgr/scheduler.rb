
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
        
        hosts.each{|ph|
          Dcmgr::logger.debug "  ph[%d].cpus: %s" % [ph.id, ph.cpus]
          Dcmgr::logger.debug "  ph[%d].cpu_mhz: %s" % [ph.id, ph.cpu_mhz]
          Dcmgr::logger.debug "  ph[%d].memory: %s" % [ph.id, ph.memory]

          instances = ph.instances
          need_cpus = instances.inject(0) {|v, ins| v + ins.need_cpus}
          need_cpu_mhz = instances.inject(0) {|v, ins| v + ins.need_cpu_mhz}
          need_memory = instances.inject(0) {|v, ins| v + ins.need_memory}
          
          Dcmgr::logger.debug "  ph[%d].instances cpus: %s" % [ph.id, need_cpus]
          Dcmgr::logger.debug "  ph[%d].instances cpu_mhz: %s" % [ph.id, need_cpu_mhz]
          Dcmgr::logger.debug "  ph[%d].instances memory: %s" % [ph.id, need_memory]
          
          space_cpus = ph.cpus - need_cpus
          space_cpu_mhz = ph.cpu_mhz - need_cpu_mhz
          space_memory = ph.memory - need_memory
        
          Dcmgr::logger.debug "  ph[%d].space cpus: %s" % [ph.id, space_cpus]
          Dcmgr::logger.debug "  ph[%d].space cpu_mhz: %s" % [ph.id, space_cpu_mhz]
          Dcmgr::logger.debug "  ph[%d].space memory: %s" % [ph.id, space_memory]
          
          if instance.need_cpus <= space_cpus and
              instance.need_cpu_mhz <= space_cpu_mhz and
              instance.need_memory <= space_memory
            Dcmgr::logger.debug "assign to instance: %s" % ph
            return ph
          end
        }
        
        raise NoPhysicalHostError.new("can't assign physical host")
      end
    end
  end
end
