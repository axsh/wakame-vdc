module Wakame
  module MasterManagers
   class ClusterManager
     include MasterManager

     class ClusterConfigLoader

       def load(cluster_rb_path=Wakame.config.cluster_config_path)
         Wakame.log.info("#{self.class}: Loading cluster.rb: #{cluster_rb_path}")
         @loaded_cluster_names = {}

         eval(File.readlines(cluster_rb_path).join(''), binding)

         # Clear uninitialized cluster data in the store.
         Service::ServiceCluster.find_all.each { |cluster|
           cluster.delete unless @loaded_cluster_names.has_key?(cluster.name)
         }

         @loaded_cluster_names
       end


       private
       def define_cluster(name, &blk)
         cluster = Service::ServiceCluster.find(Service::ServiceCluster.id(name))
         if cluster.nil?
           cluster = Service::ServiceCluster.new
           cluster.name = name
         end

         Models::AgentPool.reset
         cluster.reset

         blk.call(cluster)

         cluster.save

         Wakame.log.info("#{self.class}: Loaded Service Cluster: #{cluster.name}")
         @loaded_cluster_names[name]=cluster.id
       end

     end

     def init
       # Periodical cluster status updater
       @status_check_timer = EM::PeriodicTimer.new(5) {
         StatusDB.pass {
           clusters.each { |cluster_id|
             Service::ServiceCluster.find(cluster_id).update_cluster_status
           }
         }
       }
       
       # Event based cluster status updater
       @check_event_tickets = []
       [Event::ServiceOnline, Event::ServiceOffline, Event::ServiceFailed].each { |evclass|
         @check_event_tickets << EventDispatcher.subscribe(evclass) { |event|
           StatusDB.pass {
             clusters.each { |cluster_id|
               Service::ServiceCluster.find(cluster_id).update_cluster_status
             }
           }
         }
       }
      
       @check_event_tickets << EventDispatcher.subscribe(Event::ServiceStatusChanged) { |event|
         svc = Service::ServiceInstance.find(event.instance_id)
         case svc.status
         when Service::STATUS_ENTERING
           EM.defer {
             # Refresh the monitoring conf on the agent
             svc.cloud_host.live_monitors.each { |path, conf|
               Wakame.log.debug("#{self.class}: Refreshing monitoring setting on #{svc.cloud_host.agent_id} (on enter): #{path} => #{conf.inspect}")
               Master.instance.actor_request(svc.cloud_host.agent_id, '/monitor/reload', path, conf).request.wait
             }
           }
         when Service::STATUS_QUITTING
           EM.defer {
             # Refresh the monitoring conf on the agent
             svc.cloud_host.live_monitors.each { |path, conf|
               Wakame.log.debug("#{self.class}: Refreshing monitoring setting on #{svc.cloud_host.agent_id} (on quit): #{path} => #{conf.inspect}")
               Master.instance.actor_request(svc.cloud_host.agent_id, '/monitor/reload', path, conf).request.wait
             }
           }
         end
       }
     end

     def reload
     end

     def terminate
       @status_check_timer.cancel
       @check_event_tickets.each { |t|
         EventDispatcher.unsubscribe(t)
       }
     end

     def clusters
       Models::ServiceClusterPool.all.map{|r| r.service_cluster_id }
     end

     def register(cluster)
       raise ArgumentError unless cluster.is_a?(Service::ServiceCluster)
       Models::ServiceClusterPool.register_cluster(cluster.name)
     end

     def unregister(cluster_id)
       @clusters.delete(cluster_id)
     end

     def load_config_cluster
       ClusterConfigLoader.new.load.each { |name, id|
         Models::ServiceClusterPool.register_cluster(name)
       }
       resolve_template_vm_attr
     end


     private
     def resolve_template_vm_attr
       Models::ServiceClusterPool.each_cluster { |cluster|
         cluster_id = cluster.id

         if cluster.template_vm_attr.nil? || cluster.template_vm_attr.empty?
           update_template_spec = lambda { |agent|
             raise ArgumentError unless agent.is_a?(Service::Agent)

             require 'right_aws'
             ec2 = RightAws::Ec2.new(Wakame.config.aws_access_key, Wakame.config.aws_secret_key)
             
             ref_attr = ec2.describe_instances([agent.vm_attr[:aws_instance_id]])
             ref_attr = ref_attr[0]
                 
             cluster = Service::ServiceCluster.find(cluster_id)
             spec = cluster.template_vm_spec
             Service::VmSpec::EC2.vm_attr_defs.each { |k, v|
               spec.attrs[k] = ref_attr[v[:right_aws_key]]
             }
             cluster.save
             
             Wakame.log.debug("ServiceCluster \"#{cluster.name}\" template_vm_attr based on VM \"#{agent.vm_attr[:aws_instance_id]}\" : #{spec.attrs.inspect}")
           }


           agent_id = Models::AgentPool.instance.group_active.first
           if agent_id.nil?
             # Set a single shot event handler to set the template values up from the first connected agent.
             EventDispatcher.subscribe_once(Event::AgentMonitored) { |event|
               StatusDB.pass {
                 update_template_spec.call(event.agent)
               }
             }
           else
             StatusDB.pass {
               update_template_spec.call(Service::Agent.find(agent_id))
             }
           end
         end

         if cluster.advertised_amqp_servers.nil?
           StatusDB.pass {
             cluster = Service::ServiceCluster.find(cluster_id)
             #cluster.advertised_amqp_servers = master.amqp_server_uri.to_s
             attrs = Wakame::Master.ec2_fetch_local_attrs
             cluster.advertised_amqp_servers = "amqp://#{attrs[:local_ipv4]}/"
             cluster.save
             Wakame.log.debug("ServiceCluster \"#{cluster.name}\" advertised_amqp_servers: #{cluster.advertised_amqp_servers}")
           }
         end

       }
     end
   end
 end
end
