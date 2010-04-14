
module Wakame
  module MasterManagers
    class AgentMonitor
      include MasterManager
      include ThreadImmutable

      def init
        @agent_timeout = 31.to_f
        @agent_kill_timeout = @agent_timeout * 2
        @gc_period = 20.to_f

        # GC event trigger for agent timer & status
        @agent_timeout_timer = EM::PeriodicTimer.new(@gc_period) {
          StatusDB.pass {
            #Wakame.log.debug("Started agent GC : agents.size=#{@registered_agents.size}")
            self.agent_pool.dataset.all.each { |row|
              agent = Service::Agent.find(row[:agent_id])
              #next if agent.status == Service::Agent::STATUS_OFFLINE
              
              diff_time = Time.now - agent.last_ping_at_time
              #Wakame.log.debug "AgentMonitor GC : #{agent_id}: #{diff_time}"
              if diff_time > @agent_timeout.to_f
                agent.update_monitor_status(Service::Agent::STATUS_TIMEOUT)
              end
              
              if diff_time > @agent_kill_timeout.to_f
                agent_pool.unregister(agent)
              end
            }
            
            #Wakame.log.debug("Finished agent GC")
          }
        }
        
        
        master.add_subscriber('registry') { |data|
          data = eval(data)
          next if Time.parse(data[:responded_at]) < master.started_at
          
          StatusDB.pass {
            agent_id = data[:agent_id]
            
            agent = agent_pool.agent_find_or_create(agent_id)
            
            case data[:class_type]
            when 'Wakame::Packets::Register'
              agent.update_status(Service::Agent::STATUS_REGISTERRING)
              agent_pool.register_as_observed(agent)

              agent.root_path = data[:root_path]

              agent.save
              master.action_manager.trigger_action(Actions::RegisterAgent.new(agent))
            when 'Wakame::Packets::UnRegister'
              agent_pool.unregister(agent)
            end
          }

        }

        master.add_subscriber('ping') { |data|
          ping = eval(data)
          # Skip the old ping responses before starting master node.
          next if Time.parse(ping[:responded_at]) < master.started_at

          # Variable update function for the common members
          set_report_values = proc { |agent|
            agent.last_ping_at = ping[:responded_at]

            agent.renew_reported_services(ping[:services])
            agent.save

            agent.update_monitor_status(Service::Agent::STATUS_ONLINE)
          }
          
          StatusDB.pass { 
            agent = Service::Agent.find(ping[:agent_id])
            if agent.nil?
              agent = Service::Agent.new
              agent.id = ping[:agent_id]
              
              set_report_values.call(agent)

              agent_pool.register_as_observed(agent)
            else
              set_report_values.call(agent)
            end
            
            EventDispatcher.fire_event(Event::AgentPong.new(agent))
          }
        }
        
        master.add_subscriber('agent_event') { |data|
          response = eval(data)
          next if Time.parse(response[:responded_at]) < master.started_at

          case response[:class_type]
          when 'Wakame::Packets::StatusCheckResult'
            StatusDB.pass {
              svc_inst = Service::ServiceInstance.find(response[:svc_id])
              if svc_inst
                svc_inst.monitor_status = response[:status]
                svc_inst.save
              else
                Wakame.log.error("#{self.class}: Unknown service ID: #{response[:svc_id]}")
                agent = Service::Agent.find(response[:agent_id])
                correct_svc_monitor_mismatch(agent)
              end
            }
          when 'Wakame::Packets::ServiceStatusChanged'
            StatusDB.pass {
              svc_inst = Service::ServiceInstance.find(response[:svc_id])
              if svc_inst
                response_time = Time.parse(response[:responded_at])
                svc_inst.update_monitor_status(response[:new_status], response_time, response[:fail_message])
              end
            }
          when 'Wakame::Packets::ActorResponse'
            case response[:status]
            when Actor::STATUS_RUNNING
              EventDispatcher.fire_event(Event::ActorProgress.new(response[:agent_id], response[:token], 0))
            when Actor::STATUS_FAILED
              EventDispatcher.fire_event(Event::ActorComplete.new(response[:agent_id], response[:token], response[:status], nil))
            else
              EventDispatcher.fire_event(Event::ActorComplete.new(response[:agent_id], response[:token], response[:status], response[:opts][:return_value]))
            end
          else
            Wakame.log.warn("#{self.class}: Unhandled agent response: #{response[:class_type]}")
          end
        }

        EventDispatcher.subscribe(Event::AgentUnMonitored) { |event|
          StatusDB.pass {
            agent = Service::Agent.find(event.agent.id)
            agent.terminate
          }
        }
      end

      def terminate
        @agent_timeout_timer.cancel
      end

      def agent_pool
        Models::AgentPool.instance
      end


      private
      def correct_svc_monitor_mismatch(agent)
        if agent.mapped?
          agent.cloud_host.live_monitors.each { |path, conf|
            Wakame.log.debug("#{self.class}: Refreshing monitoring setting on #{agent.id}: #{path} => #{conf.inspect}")
            agent.actor_request('/monitor/reload', path, conf).request
          }
        else
          Wakame.log.debug("#{self.class}: Resetting monitoring setting on #{agent.id}")
          agent.actor_request('/monitor/reload', '/service', {}).request
        end
        
      end

    end
  end
end
