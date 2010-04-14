module Wakame
  module Actions
    class ShutdownVM < Action
      def initialize(agent)
        raise ArgumentError unless agent.is_a?(Service::Agent)
        @agent = agent
      end

      def run
        if @agent.mapped?
          cloud_host = @agent.cloud_host
          raise "The VM has running service(s)." if cloud_host.assigned_services.any? {|svc_id|
            Wakame::Service::ServiceInstance.find(svc_id).monitor_status == Wakame::Service::STATUS_ONLINE
          }
        end

        require 'uri'
        require 'socket'
        Master.instance.cluster_manager.clusters.each { |cluster_id|
          cluster = Service::ServiceCluster.find(cluster_id)
          next if cluster.advertised_amqp_servers.nil?
          amqp_uri = URI.parse(cluster.advertised_amqp_servers)
          amqp_svr_ip = IPSocket.getaddress(amqp_uri.host)
          
          [@agent.vm_attr[:dns_name], @agent.vm_attr[:private_dns_name]].each { |hostname|
            if IPSocket.getaddress(hostname) == amqp_svr_ip
              Wakame.log.info("Skip to shutdown the VM as the master is running on this node: #{@agent.id}")
              return
            end
          }
        }

        StatusDB.barrier {
          @agent.update_status(Service::Agent::STATUS_TERMINATING)
        }
        shutdown_ec2_instance

      end

      private
      def shutdown_ec2_instance
        require 'right_aws'
        ec2 = RightAws::Ec2.new(Wakame.config.aws_access_key, Wakame.config.aws_secret_key, {:cache=>false})

        res = ec2.terminate_instances([@agent.vm_attr[:aws_instance_id]])
      end
    end
  end
end
