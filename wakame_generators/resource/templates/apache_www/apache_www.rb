class Apache_WWW < Wakame::Service::Resource
  include HttpServer
  include HttpAssetServer

  update_attribute :listen_port, 8000
  update_attribute :monitors, {'/service' => {
      :type => :pidfile,
      :path => '/var/run/apache2-www.pid'
    }
  }
  
  def render_config(template)
    template.glob_basedir(%w(conf/envvars-www init.d/apache2-www)) { |d|
      template.cp(d)
    }
    template.glob_basedir(%w(conf/system-www.conf conf/apache2.conf conf/vh/*.conf)) { |d|
      template.render(d)
    }
    template.chmod("init.d/apache2-www", 0755)
  end
  
  def start(svc, action)
    cond = ConditionalWait.new { |cond|
      cond.wait_event(Wakame::Event::ServiceOnline) { |event|
        event.instance_id == svc.id
      }
    }

    action.actor_request(svc.cloud_host.agent_id,
                         '/daemon/start', "apache_www", 'init.d/apache2-www'){ |req|
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
                         '/daemon/stop', 'apache_www', 'init.d/apache2-www'){ |req|
      req.wait
      Wakame.log.debug("#{self.class} process stooped")
    }
    cond.wait
  end
  
  def reload(svc, action)
    action.actor_request(svc.cloud_host.agent_id,
                         '/daemon/reload', 'apache_www', 'init.d/apache2-www'){ |req|
      req.wait
      Wakame.log.debug("#{self.class} process reloaded")
    }
  end
  
end
