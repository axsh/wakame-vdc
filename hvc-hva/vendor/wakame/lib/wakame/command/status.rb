
class Wakame::Command::Status
  include Wakame::Command
  include Wakame::Service

  def run
    Wakame::StatusDB.barrier {
      res = {
        :cluster=>nil, 
        :agent_pool=>nil, 
        :agents=>{}, 
        :services=>{}, 
        :resources=>{},
        :cloud_hosts=>{}
      }

      res[:agent_pool] = {
        :group_active => Wakame::Models::AgentPool.instance.group_active,
        :group_observed => Wakame::Models::AgentPool.instance.group_observed
      }
      Wakame::Models::AgentPool.instance.dataset.all.each { |row|
        res[:agents][row[:agent_id]] = Agent.find(row[:agent_id]).dump_attrs
      }

      cluster_id = master.cluster_manager.clusters.first
      if cluster_id
        cluster = ServiceCluster.find(cluster_id)
        res[:cluster] = cluster.dump_attrs
        cluster.services.keys.each { |id|
          res[:services][id]=ServiceInstance.find(id).dump_attrs
        }
        
        cluster.resources.keys.each { |id|
          res[:resources][id]=Resource.find(id).dump_attrs
        }
        
        cluster.cloud_hosts.keys.each { |id|
          res[:cloud_hosts][id]=CloudHost.find(id).dump_attrs
        }
      end
      res
    }

  end
end
