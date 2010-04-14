require 'wakame/util'

module Wakame
  module Event
    class Base
      attr_accessor :time

      def initialize
        @time = Time.now
      end

      def log_message
      end
    end


    class ClusterStatusChanged  < Base
      attr_reader :instance_id, :status
      def initialize(instance_id, status)
        super()
        @instance_id = instance_id
        @status = status
      end

      def log_message
        "#{instance_id}, #{@status}"
      end

    end

    class ClusterFrozen < Base
      attr_reader :cluster_id
      def initialize(cluster_id)
        super()
        @cluster_id = cluster_id
      end

      def log_message
        "#{@cluster_id}, frozen"
      end
    end

    class ClusterUnfrozen < Base
      attr_reader :cluster_id
      def initialize(cluster_id)
        super()
        @cluster_id = cluster_id
      end

      def log_message
        "#{@cluster_id}, unfrozen"
      end
    end

    class ServiceStatus < Base
      attr_reader :instance_id
      def initialize(instance_id)
        super()
        @instance_id = instance_id
      end
    end

    # Event class for the change of ServiceInstance#status
    class ServiceStatusChanged < ServiceStatus
      attr_reader :status, :previous_status
      def initialize(instance_id, new_status, prev_status)
        super(instance_id)
        @status = new_status
        @previous_status = prev_status
      end

      def log_message
        "#{instance_id}, #{@previous_status} -> #{@status}"
      end
    end


    # Event class for the change of ServiceInstance#monitor_status
    class ServiceMonitorStatusChanged < ServiceStatus
      attr_reader :status, :previous_status
      def initialize(instance_id, new_status, prev_status)
        super(instance_id)
        @status = new_status
        @previous_status = prev_status
      end

      def log_message
        "#{instance_id}, #{@previous_status} -> #{@status}"
      end
    end

    class ServiceOnline < ServiceStatus
    end
    class ServiceOffline < ServiceStatus
    end
    class ServiceFailed < ServiceStatus
      attr_reader :message
      def initialize(instance_id, message)
        super(instance_id)
        @message = message
      end
    end

    class ServicePropagated < ServiceStatus
    end
    class ServiceDestroied < ServiceStatus
    end

    class AgentMappedCloudHost < Base
      attr_reader :agent_id, :cloud_host_id
      def initialize(cloud_host_id, agent_id)
        super()
        @agent_id = agent_id
        @cloud_host_id = cloud_host_id
      end
    end
    class AgentUnmappedCloudHost < Base
      attr_reader :agent_id, :cloud_host_id
      def initialize(cloud_host_id, agent_id)
        super()
        @agent_id = agent_id
        @cloud_host_id = cloud_host_id
      end
    end

    class AgentEvent < Base
      attr_reader :agent
      def initialize(agent)
        super()
        @agent = agent
      end
    end

    class AgentPong < AgentEvent
    end

    class AgentTimedOut < AgentEvent
    end
    class AgentMonitored < AgentEvent
    end
    class AgentUnMonitored < AgentEvent
    end
    class AgentStatusChanged < AgentEvent
    end


    class ServiceUnboundAgent < Base
      attr_reader :service, :agent
      def initialize(service, agent)
        super()
        @service = service
        @agent = agent
      end
    end
    class ServiceBoundAgent < Base
      attr_reader :service, :agent
      def initialize(service, agent)
        super()
        @service = service
        @agent = agent
      end
    end

    class ServiceUnboundCloudHost < Base
      attr_reader :svc_id, :cloud_host_id
      def initialize(svc_id, cloud_host_id)
        super()
        @svc_id = svc_id
        @cloud_host_id = cloud_host_id
      end
    end
    class ServiceBoundCloudHost < Base
      attr_reader :svc_id, :cloud_host_id
      def initialize(svc_id, cloud_host_id)
        super()
        @svc_id = svc_id
        @cloud_host_id = cloud_host_id
      end
    end

    class ServiceBoundCluster < Base
      attr_reader :service, :service_cluster
      def initialize(svc_inst, cluster)
        super()
        @service = svc_inst
        @service_cluster = cluster
      end
    end

    class ServiceUnboundCluster < Base
      attr_reader :service, :service_cluster
      def initialize(svc_inst, cluster)
        super()
        @service = svc_inst
        @service_cluster = cluster
      end
    end

    class CommandReceived < Base
      attr_reader :command
      def initialize(command)
        @command = command
      end
    end

    class ActionEvent < Base
      attr_reader :action
      def initialize(action)
        super()
        @action = action
      end

      def log_message
        "#{@action.class}, job_id=#{@action.job_id}"
      end

    end

    class ActionStart < ActionEvent
    end
    class ActionComplete < ActionEvent
    end
    class ActionFailed < ActionEvent
      attr_reader :exception
      def initialize(action, e)
        super(action)
        @exception = e
      end
    end

    class JobEvent < Base
      attr_reader :job_id
      def initialize(job_id)
        super()
        @job_id = job_id
      end

      def log_message
        "#{@job_id}"
      end
    end
    class JobStart < JobEvent
    end
    class JobComplete < JobEvent
      attr_reader :status
      def initialize(job_id, status)
        super(job_id)
        @status = status
      end
    end
    class JobSuccess < JobEvent
    end
    class JobFailed < JobEvent
      attr_reader :exception
      def initialize(job_id, e)
        super(job_id)
        @exception = e
      end
    end
    

    class AgentShutdown < Base; end
    class MasterShutdown < Base; end

    class InstanceCountChanged < Base
      attr_reader :resource, :prev_count, :count
      def initialize(resource, prev_count, count)
        @resource = resource
        @prev_count = prev_count
        @count = count
      end

      def increased?
        @prev_count < @count
      end

      def decreased?
        @prev_count > @count
      end
    end

    class ActorProgress < Base
      attr_reader :agent_id, :token, :progress
      def initialize(agent_id, token, progress)
        @agent_id = agent_id
        @token = token
        @progress  = progress
      end
    end

    class ActorComplete < Base
      attr_reader :agent_id, :token, :status, :return_value
      def initialize(agent_id, token, status, return_value)
        @agent_id = agent_id
        @token = token
        @status = status
        @return_value = return_value
      end
    end

  end
end
