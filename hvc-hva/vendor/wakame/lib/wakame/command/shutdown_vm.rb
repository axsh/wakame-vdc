
class Wakame::Command::ShutdownVm
  include Wakame::Command

  command_name 'shutdown_vm'

  def run
    agent = Wakame::Models::AgentPool.instance.find_agent(@options['agent_id'])
    if agent.cloud_host_id.nil?
      trigger_action(Wakame::Actions::ShutdownVM.new(agent))
    else
      cloud_host = agent.cloud_host
      # Check if the agent has the running service(s).
      live_svcs = cloud_host.assigned_services.find_all {|svc_id|
        Wakame::Service::ServiceInstance.find(svc_id).monitor_status == Wakame::Service::STATUS_ONLINE
      }
      if live_svcs.empty?
        cloud_host.unmap_agent
        trigger_action(Wakame::Actions::ShutdownVM.new(agent))
      else
        raise "Service(s) are still running on #{agent.id}" unless @options['force']
        
        trigger_action { |action|
          live_svcs.each {|svc_id|
            svc = Wakame::Service::ServiceInstance.find(svc_id)
            action.trigger_action(Wakame::Actions::StopService.new(svc))
          }
          action.flush_subactions

          Wakame::StatusDB.barrier {
            cluster = Wakame::Service::ServiceCluster.find(cloud_host.cluster_id)
            live_svcs.each {|svc_id|
              cluster.destroy(svc_id)
            }
            
            cloud_host.unmap_agent
            cluster.remove_cloud_host(cloud_host.id)
          }

          action.trigger_action(Wakame::Actions::ShutdownVM.new(agent))
        }
      end
    end
      
  end
end
