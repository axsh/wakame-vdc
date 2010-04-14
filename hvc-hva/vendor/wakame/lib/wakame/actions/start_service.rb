
module Wakame
  module Actions
    class StartService < Action
      def initialize(svc)
        @svc = svc
      end

      def run
        acquire_lock(@svc.resource.class.to_s)
        @svc.reload

        # Skip to act when the service is having below status.
        if @svc.status == Service::STATUS_RUNNING && @svc.monitor_status == Service::STATUS_ONLINE
          Wakame.log.info("Ignore to start the service as is being or already Online: #{@svc.resource.class}")
          return
        end

        if @svc.resource.require_agent
          raise "The service is not bound cloud host object: #{@svc.id}" if @svc.cloud_host_id.nil?

          unless @svc.cloud_host.mapped?
            acquire_lock(Models::AgentPool.to_s)
            
            # Try to arrange agent from existing agent pool.
            StatusDB.barrier {
              next if Models::AgentPool.group_active.empty?
              agent2host = cluster.agents.invert
              
              Models::AgentPool.group_active.each { |agent_id|
                agent = Service::Agent.find(agent_id)
                if !agent.has_resource_type?(@svc.resource) &&
                    agent2host[agent_id].nil? && # This agent is not mapped to any cloud hosts.
                    @svc.cloud_host.vm_spec.satisfy?(agent.vm_attr)
                  
                  @svc.cloud_host.map_agent(agent)
                  break
                end
              }
            }
            
            # Start new VM when the target agent is still nil.
            unless @svc.cloud_host.mapped?
              inst_id_key = "new_inst_id_" + Wakame::Util.gen_id
              trigger_action(LaunchVM.new(inst_id_key, @svc.cloud_host.vm_spec))
              flush_subactions
              
              StatusDB.barrier {
                agent = Service::Agent.find(notes[inst_id_key])
                raise "Cound not find the specified VM instance \"#{notes[inst_id_key]}\"" if agent.nil?
                @svc.cloud_host.map_agent(agent)
              }
            end
            
            raise "Could not find the agent to be assigned to : #{@svc.resource.class}" unless @svc.cloud_host.mapped?
          end
          
          raise "The assigned agent \"#{@svc.cloud_host.agent_id}\" for the service instance #{@svc.id} is not online."  unless @svc.cloud_host.agent.monitor_status == Service::Agent::STATUS_ONLINE
          
          StatusDB.barrier {
            @svc.update_status(Service::STATUS_ENTERING)
          }

          @svc.resource.on_enter_agent(@svc, self)
        end
        

        StatusDB.barrier {
          @svc.update_status(Service::STATUS_STARTING)
        }
        
        if @svc.resource.require_agent
          trigger_action(DeployConfig.new(@svc))
          flush_subactions
        end

        @svc.reload
        Wakame.log.debug("#{@svc.resource.class}: svc.monitor_status == Wakame::Service::STATUS_ONLINE => #{@svc.monitor_status == Wakame::Service::STATUS_ONLINE}")
        if @svc.monitor_status != Wakame::Service::STATUS_ONLINE
          @svc.resource.start(@svc, self)
        end

        StatusDB.barrier {
          @svc.update_status(Service::STATUS_RUNNING)
        }
        
        trigger_action(NotifyParentChanged.new(@svc))
        flush_subactions

      end

      def on_failed
        StatusDB.barrier {
          @svc.update_status(Service::STATUS_FAIL)
        }
      end
    end
  end
end
