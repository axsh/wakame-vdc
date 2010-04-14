define_cluster('WebCluster1') { |c|
  c.add_resource(Apache_APP.new) { |r|
    r.listen_port = 8001
    r.max_instances = 5
  }
  c.add_resource(Nginx.new)
  c.add_resource(Ec2ELB.new) { |r|
    r.elb_name = 'xxxxxxx'
  }
  c.add_resource(MySQL_Master.new) {|r|
    r.mysqld_basedir = '/home/wakame/mysql'
    r.ebs_volume = 'vol-xxxxxxx'
    r.ebs_device = '/dev/sdm'
  }
  
  c.set_dependency(Apache_APP, Nginx)
  c.set_dependency(Nginx, Ec2ELB)
  c.set_dependency(MySQL_Master, Apache_APP)

  host = c.add_cloud_host { |h|
    #h.vm_spec.availability_zone = 'us-east-1a'
  }
  c.propagate(Nginx, host.id)
  c.propagate(Apache_APP, host.id)
  c.propagate(MySQL_Master, host.id)
  c.propagate(Ec2ELB)

  c.define_triggers {|r|
    #r.register_trigger(Wakame::Triggers::MaintainSshKnownHosts.new)
    #r.register_trigger(Wakame::Triggers::LoadHistoryMonitor.new)
    #r.register_trigger(Wakame::Triggers::InstanceCountUpdate.new)
    #r.register_trigger(Wakame::Triggers::ScaleOutWhenHighLoad.new)
    #r.register_trigger(Wakame::Triggers::ShutdownUnusedVM.new)
  }

}

