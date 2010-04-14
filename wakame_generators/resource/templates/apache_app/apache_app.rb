class Apache_APP < Wakame::Service::Resource
  include HttpServer
  include HttpApplicationServer

  update_attribute :listen_port, 8001
  update_attribute :monitors, {'/service' => {
      :type => :pidfile,
      :path => '/var/run/apache2-app.pid'
    }
  }

  def render_config(template)
    template.glob_basedir(%w(conf/envvars-app init.d/apache2-app)) { |d|
      template.cp(d)
    }
    template.glob_basedir(%w(conf/system-app.conf conf/apache2.conf conf/vh/*.conf)) { |d|
      template.render(d)
    }
    template.chmod("init.d/apache2-app", 0755)
  end

  def on_reload_application(svc, action, repo_data)
    action.actor_request(svc.cloud_host.agent_id, '/system/touch',
                         File.join(application_root_path, repo_data[:app_name], 'current', 'tmp', 'restart.txt')
                         ).request.wait
  end



  def start(svc, action)
    cond = ConditionalWait.new { |cond|
      cond.wait_event(Wakame::Event::ServiceOnline) { |event|
        event.instance_id == svc.id
      }
    }

    action.actor_request(svc.cloud_host.agent_id,
                         '/daemon/start', "apache_app", 'init.d/apache2-app'){ |req|
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
    
    request = action.actor_request(svc.cloud_host.agent_id,
                                   '/daemon/stop', 'apache_app', 'init.d/apache2-app'){ |req|
      req.wait
      Wakame.log.debug("#{self.class} process stopped")
    }
    cond.wait
  end

  def reload(svc, action)
    action.actor_request(svc.cloud_host.agent_id,
                         '/daemon/reload', "apache_app", 'init.d/apache2-app'){ |req|
      req.wait
      Wakame.log.debug("#{self.class} process reloaded")
    }
  end

end
