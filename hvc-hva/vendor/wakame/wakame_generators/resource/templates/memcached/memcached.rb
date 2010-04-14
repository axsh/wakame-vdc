class Memcached < Wakame::Service::Resource

  property :listen_port,  {:default => 11211 }
  property :bind_address, {:default => '127.0.0.1'}
  property :memory_size,  {:default => 64}
  property :user,         {:default => 'nobody'}

  def render_config(template)
    template.cp('init.d/memcached')
    template.render('conf/memcached.conf')
    template.chmod("init.d/memcached", 0755)
  end

  def on_parent_changed(svc, action)
    action.trigger_action(Wakame::Actions::DeployConfig.new(svc))
    action.flush_subactions
    reload(svc, action)
  end

  def start(svc, action)
    cond = ConditionalWait.new { |cond|
      cond.wait_event(Wakame::Event::ServiceOnline) { |event|
        event.instance_id == svc.id
      }
    }

    request = action.actor_request(svc.cloud_host.agent_id,
                                   '/service_monitor/register',
                                   svc.id, :pidfile, '/var/run/memcached.pid').request
    action.actor_request(svc.cloud_host.agent_id,
                         '/daemon/start', "memcached", 'init.d/memcached'){ |req|
      req.wait
      Wakame.log.debug("#{self.class} process started")
    }
    
    cond.wait
  end
  
  def stop(svc, action)
    cond = ConditionalWait.new { |cond|
      cond.wait_event(Wakame::Event::ServiceOffline) { |event|
        event.instance_id == svc.id
      }
    }

    action.actor_request(svc.cloud_host.agent_id,
                         '/daemon/stop', 'memcached', 'init.d/memcached'){ |req|
      req.wait
      Wakame.log.debug("#{self.class} process stopped")
    }

    cond.wait

    request = action.actor_request(svc.cloud_host.agent_id,
                                   '/service_monitor/unregister', svc.instance_id).request
  end

  def reload(svc, action)
    action.actor_request(svc.cloud_host.agent_id,
                         '/daemon/stop', 'memcached', 'init.d/memcached'){ |req|
      req.wait
      # Wakame.log.debug("#{self.class} process stopped")
    }

    action.actor_request(svc.cloud_host.agent_id,
                         '/daemon/start', "memcached", 'init.d/memcached'){ |req|
      req.wait
      # Wakame.log.debug("#{self.class} process started")
      Wakame.log.debug("#{self.class} process reloaded")
    }
  end
  
end
