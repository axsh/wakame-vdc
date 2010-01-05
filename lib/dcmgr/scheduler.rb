
module Dcmgr
  module PhysicalHostScheduler
    module Algorithm1
      def assign_to_instance(hosts, instance)
        Dcmgr::logger.debug "alrogithm 1 schedule instance--"
        hosts[1]
      end
    end
    
    module Algorithm2
      def assign_to_instance(hosts, instance)
        Dcmgr::logger.debug "schedule instance--"
        
        hosts.each{|ph|
          Dcmgr::logger.debug "  ph[%d].cpus: %s" % [ph.id, ph.cpus]
          Dcmgr::logger.debug "  ph[%d].cpu_mhz: %s" % [ph.id, ph.cpu_mhz]
          Dcmgr::logger.debug "  ph[%d].memory: %s" % [ph.id, ph.memory]
          
          Dcmgr::logger.debug "  ph[%d].instances cpus: %s" % [ph.id, ph.instances_dataset.sum(:need_cpus)]
          Dcmgr::logger.debug "  ph[%d].instances cpu_mhz: %s" % [ph.id, ph.instances_dataset.sum(:need_cpu_mhz)]
          Dcmgr::logger.debug "  ph[%d].instances memory: %s" % [ph.id, ph.instances_dataset.sum(:need_memory)]
          
          space_cpus = ph.cpus - (ph.instances_dataset.sum(:need_cpus) or 0)
          space_cpu_mhz = ph.cpu_mhz - (ph.instances_dataset.sum(:need_cpu_mhz) or 0)
          space_memory = ph.memory - (ph.instances_dataset.sum(:need_memory) or 0)
        
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
        Dcmgr::logger.debug ""
        raise NoPhysicalHostException
      end
    end
  end
end
