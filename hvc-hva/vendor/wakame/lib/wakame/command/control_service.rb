class Wakame::Command::ControlService
  include Wakame::Command
  include Wakame

  command_name 'control_service'

  def run
    num = @options["number"] || 1
    raise "Invalid format of number: #{num}" unless /^(\d+)$/ =~ num.to_s
    num = num.to_i

    resname = @options["resource"]
    resobj = Service::Resource.find(Service::Resource.id(resname))

    if num < 1 || resobj.max_instances < num 
      raise "The number must be between 1 and #{resobj.max_instances - service_cluster.instance_count(resobj)} (max limit: #{resobj.max_instances})"
    end
    raise "The same number of instances running" if service_cluster.instance_count(resobj) == num

    if service_cluster.instance_count(resobj) < num
      num = (num - service_cluster.instance_count(resobj)).to_i
      cloud_host_id = nil
      refsvc = service_cluster.find_service(@options["service_id"])
      if refsvc.nil?
        raise("Unknown ServiceInstance ID: #{@options["service_id"]}")
      end
      trigger_action{|action|
        num.times{
          action.trigger_action(Wakame::Actions::PropagateService.new(refsvc, cloud_host_id))
        }
      }
    else
      attrs = Master.ec2_fetch_local_attrs
      agent = Wakame::Models::AgentPool.instance.find_agent(attrs[:instance_id])
      cloud_host_id = agent.cloud_host.id
      num = (service_cluster.instance_count(resobj) - num).to_i
      locksvc = service_cluster.find_service(@options["service_id"])
      refsvc = service_cluster.each_instance(resobj)
      svcs, nsvcs = refsvc.partition{|s| s.id == locksvc.id}
      c = 1
      res = {}
      nsvcs.reverse_each {|svc|
        cloud_host = Service::CloudHost.find(svc.cloud_host_id)
        res[svc.id] =  cloud_host.agent.vm_attr
        trigger_action { |action|
          action.trigger_action(Wakame::Actions::StopService.new(svc))
          action.flush_subactions
          action.trigger_action(Wakame::Actions::NotifyParentChanged.new(svc))
          action.flush_subactions
          unless cloud_host.id == cloud_host_id
            action.trigger_action(Wakame::Actions::ShutdownVM.new(cloud_host.agent))
            action.flush_subactions
            Wakame::StatusDB.barrier{
              cluster = Wakame::Service::ServiceCluster.find(cloud_host.cluster_id)
              cloud_host.unmap_agent
              cluster.remove_cloud_host(cloud_host.id)
            }
          end
        }
        c += 1
        break if c > num
      }
    end
    res
  end
end
