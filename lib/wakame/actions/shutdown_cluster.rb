module Wakame
  module Actions
    class ShutdownCluster < Action
      def run
        levels = cluster.dg.levels
        Wakame.log.debug("#{self.class}: Resource shutdown order: " + levels.collect {|lv| '['+ lv.collect{|prop| "#{prop.class}" }.join(', ') + ']' }.join(', '))
        acquire_lock(levels.map {|lv| lv.map{|res| res.class.to_s } })

        levels.reverse.each { |lv|
          lv.each { |svc_prop|
            service_cluster.each_instance(svc_prop.class) { |svc_inst|
              trigger_action(StopService.new(svc_inst))
            }
          }
          flush_subactions
        }
        cluster.cloud_hosts.keys.each { |cloud_host_id|
          cloud_host = Service::CloudHost.find(cloud_host_id)
          trigger_action(ShutdownVM.new(cloud_host.agent))
        }
      end
    end
  end
end
