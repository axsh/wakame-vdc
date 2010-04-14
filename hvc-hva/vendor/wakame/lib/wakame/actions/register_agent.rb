module Wakame
  module Actions
    class RegisterAgent < Action
      def initialize(agent)
        @agent = agent
      end

      def run
        Wakame.log.debug("#{self.class}: run() begin: #{@agent.id}")
        
        acquire_lock("Agent:#{@agent.id}")

        StatusDB.barrier {
          @agent.update_vm_attr
        }
        
        # Send monitoring conf
        if @agent.cloud_host_id
          Wakame.log.debug("#{self.class}: #{@agent.id} is to be set the monitor conf: #{@agent.cloud_host.live_monitors.inspect}")
          StatusDB.barrier {
            @agent.cloud_host.live_monitors.each { |path, data|
              master.actor_request(@agent.id, '/monitor/reload', path, data).request.wait
            }
          }
        end

        StatusDB.barrier {
          @agent.update_status(Service::Agent::STATUS_RUNNING)
          @agent.update_monitor_status(Service::Agent::STATUS_ONLINE)
          Models::AgentPool.instance.register(@agent)
        }
        Wakame.log.debug("#{self.class}: run() end: #{@agent.id}")
      end

      def on_fail
        StatusDB.barrier {
          @agent.update_status(Service::Agent::STATUS_FAIL)
        }
      end

    end
  end
end
