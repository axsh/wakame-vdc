define_cluster('WebCluster1') { |c|

  host = c.add_cloud_host { |h|
    #h.vm_spec.availability_zone = 'us-east-1a'
  }

  c.define_triggers {|r|
    #r.register_trigger(Wakame::Triggers::MaintainSshKnownHosts.new)
    #r.register_trigger(Wakame::Triggers::LoadHistoryMonitor.new)
    #r.register_trigger(Wakame::Triggers::InstanceCountUpdate.new)
    #r.register_trigger(Wakame::Triggers::ScaleOutWhenHighLoad.new)
    #r.register_trigger(Wakame::Triggers::ShutdownUnusedVM.new)
  }

}

