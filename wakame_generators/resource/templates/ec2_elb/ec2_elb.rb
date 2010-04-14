class Ec2ELB < Wakame::Service::Resource
  
  property :elb_name
  property :just_unregister_when_stop, false
  update_attribute :require_agent, false
  
  def on_parent_changed(svc, action)
    start(svc, action)
  end

  def start(svc, action)
    elb = create_elb

    parents = svc.parent_instances.dup

    vm_slice_ids = parents.collect{|a| a.cloud_host.agent.vm_attr[:aws_instance_id] }.uniq
    av_zones = parents.collect{|a| a.cloud_host.agent.vm_attr[:aws_availability_zone] }.uniq
    Wakame.log.info("Setting up the ELB #{self.elb_name} with #{vm_slice_ids.join(', ')}")
    begin
      res = elb.describe_load_balancers(self.elb_name)
      elbdesc = res[0]
    rescue RightAws::AwsError => e
      if e.include?(/\ALoadBalancerNotFound\Z/)

        elb.create_load_balancer(self.elb_name, av_zones,[{ :protocol => :http, :load_balancer_port => 80,  :instance_port => 80 },
                                                          { :protocol => :tcp,  :load_balancer_port => 443, :instance_port => 443 } ])
      else
        Wakame.log.error(e.errors.inspect)
        raise e
      end

      res = elb.describe_load_balancers(self.elb_name)
      elbdesc = res[0]
    end

    elb_members, elb_not_members = vm_slice_ids.partition{|i| elbdesc[:instances].member?(i) }
    unless elb_not_members.empty?
      elb.register_instances_with_load_balancer(self.elb_name, *elb_not_members)
    end

    svc.update_monitor_status(Wakame::Service::STATUS_ONLINE)
  end
  
  def stop(svc, action)
    elb = create_elb

    if self.just_unregister_when_stop
      parents = svc.parent_instances.dup
      vm_slice_ids = parents.collect{|a| a.cloud_host.agent.vm_attr[:aws_instance_id] }.uniq
      Wakame.log.info("Deregistering the VM instances (#{vm_slice_ids.join(', ')}) from ELB #{self.elb_name}")

      elb.deregister_instances_with_load_balancer(self.elb_name, *vm_slice_id)
    else
      Wakame.log.info("Destroying the ELB #{self.elb_name}.")
      # Ignore errors in case of any issues.
      begin
        elb.delete_load_balancer(self.elb_name)
      rescue => e
        Wakame.log.error(e)
      end
    end

    svc.update_monitor_status(Wakame::Service::STATUS_OFFLINE)
  end

  private
  def create_elb
    require 'right_aws'
    RightAws::ElbInterface.new(Wakame.config.aws_access_key, Wakame.config.aws_secret_key)
  end

  def setup_elb
    elb = create_elb
  end

end
