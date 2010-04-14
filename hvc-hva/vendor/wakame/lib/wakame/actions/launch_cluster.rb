module Wakame
  module Actions
    class LaunchCluster < Action
      def initialize
      end

      def run
        if service_cluster.status == Service::ServiceCluster::STATUS_ONLINE
          Wakame.log.info("Ignore to launch the cluster as is already ONLINE: #{service_cluster.name}")
          return
        end

        levels = service_cluster.dg.levels
        Wakame.log.debug("#{self.class}: Scheduled resource launch order: " + levels.collect {|lv| '['+ lv.collect{|prop| "#{prop.class}" }.join(', ') + ']' }.join(', '))
        acquire_lock(levels.map {|lv| lv.map{|res| res.class.to_s } })

        levels.each { |lv|
          Wakame.log.info("#{self.class}: Launching resources: #{lv.collect{|prop| "#{prop.class}" }.join(', ')}")
          lv.each { |resource|
            cluster.each_instance(resource) { |svc|
              trigger_action(StartService.new(svc))
            }
          }
          flush_subactions
        }
      end

    end
  end
end
