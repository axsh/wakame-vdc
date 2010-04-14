module Wakame
  module Actions
    class DestroyInstances < Action
      def initialize(svc_prop)
        @svc_prop = svc_prop
      end

      def run
        svc_to_stop=[]

        EM.barrier {
          online_svc = []
          service_cluster.each_instance(@svc_prop.class) { |svc_inst|
            if svc_inst.status == Service::STATUS_ONLINE
              online_svc << svc_inst
            end
          }

          svc_count = service_cluster.instance_count(@svc_prop)
          if svc_count < online_svc.size
            online_svc.delete_if { |svc|
              svc.agent.agent_id == master.attr[:instance_id]
            }
        
            ((online_svc.size - svc_count) + 1).times {
              svc_to_stop << online_svc.shift
            }
            Wakame.log.debug("#{self.class}: online_svc.size=#{online_svc.size}, svc_to_stop.size=#{svc_to_stop.size}")
          end
        }

        svc_to_stop.each { |svc_inst|
          trigger_action(StopService.new(svc_inst))
        }
        flush_subactions
      end
    end
  end
end
