class Ec2ElasticIp < Wakame::Service::Resource
  
  property :elastic_ip
  property :disassociate_ip, {:default=>true}
  update_attribute :require_agent, false
  
  def on_parent_changed(svc, action)
    start(svc, action)
  end

  def start(svc, action)
    require 'right_aws'
    ec2 = RightAws::Ec2.new(Wakame.config.aws_access_key, Wakame.config.aws_secret_key)

    a = svc.parent_instances.first

    Wakame.log.info("Associating the Elastic IP #{self.elastic_ip} to #{a.cloud_host.agent.vm_attr[:aws_instance_id]}")
    ec2.associate_address(a.cloud_host.agent.vm_attr[:aws_instance_id], self.elastic_ip)

    svc.update_monitor_status(Wakame::Service::STATUS_ONLINE)
  end
  
  def stop(svc, action)
    if self.disassociate_ip
      require 'right_aws'
      ec2 = RightAws::Ec2.new(Wakame.config.aws_access_key, Wakame.config.aws_secret_key)
      
      a = svc.parent_instances.first
      
      Wakame.log.info("Disassociating the Elastic IP #{self.elastic_ip} from #{a.cloud_host.agent.vm_attr[:aws_instance_id]}")
      ec2.disassociate_address(self.elastic_ip)
    end
    
    svc.update_monitor_status(Wakame::Service::STATUS_OFFLINE)
  end

end
