
class MySQL_Slave < Wakame::Service::Resource

  property :mysqld_basedir, {:default=>'/home/wakame/mysql'}
  property :mysqld_port, {:default=>3307}

  property :ebs_device
  property :ebs_mount_option, {:default=>'noatime'}

  def basedir
    File.join(Wakame.config.root_path, 'cluster', 'resources', 'mysql_slave')
  end
  
  def mysqld_datadir
    File.expand_path('data-slave', mysqld_basedir)
  end

  def mysqld_log_bin
    File.expand_path('mysql-bin.log', mysqld_datadir)
  end

  def render_config(template)
    template.cp('init.d/mysql-slave')
    template.render('conf/my.cnf')
    template.chmod('init.d/mysql-slave', 0755)
  end

  def start(svc, action)
    cond = ConditionalWait.new { |cond|
      cond.wait_event(Wakame::Event::ServiceOnline) { |event|
        event.instance_id == svc.id
      }
    }

    action.actor_request(svc.cloud_host.agent_id,
                         '/service_monitor/register',
                         svc.id,
                         :command, "/usr/bin/mysqladmin --defaults-file=#{svc.cloud_host.root_path}/tmp/config/mysql_slave/conf/my.cnf ping > /dev/null") { |req|
    }

    opt_map = {
      :aws_access_key => Wakame.config.aws_access_key,
      :aws_secret_key => Wakame.config.aws_secret_key,
      :ebs_device     => self.ebs_device,
      :master_ip      => svc.cluster.fetch_mysql_master_ip,
    }
    svc.cluster.each_instance(MySQL_Master) { |mysql_master|
      opt_map[:master_port]           = mysql_master.resource.mysqld_port
      opt_map[:master_ebs_volume]     = mysql_master.resource.ebs_volume
      opt_map[:master_mysqld_datadir] = mysql_master.resource.mysqld_datadir
      opt_map[:repl_user]             = mysql_master.resource.repl_user
      opt_map[:repl_pass]             = mysql_master.resource.repl_pass
    }

    action.actor_request(svc.cloud_host.agent_id, '/mysql/take_master_snapshot', opt_map) { |req|
      req.wait
      Wakame.log.debug("take-master-snapshot!!")
    }

    action.actor_request(svc.cloud_host.agent_id, '/system/sync') { |req|
      req.wait
      Wakame.log.debug("sync")
    }

    action.actor_request(svc.cloud_host.agent_id, '/system/mount', self.ebs_device, self.mysqld_datadir, self.ebs_mount_option) { |req|
      req.wait
      Wakame.log.debug("MySQL volume was mounted: #{self.mysqld_datadir}")
    }

    action.actor_request(svc.cloud_host.agent_id, '/daemon/start', 'mysql_slave', 'init.d/mysql-slave') { |req|
      req.wait
      Wakame.log.debug("MySQL process started")
    }

  end
  
  def stop(svc, action)
    cond = ConditionalWait.new { |c|
      c.wait_event(Wakame::Event::ServiceOffline) { |event|
        event.instance_id == svc.id
      }
    }
    action.actor_request(svc.cloud_host.agent_id, '/daemon/stop', 'mysql_slave', 'init.d/mysql-slave') { |req| req.wait }
    action.actor_request(svc.cloud_host.agent_id, '/system/umount', self.mysqld_datadir) { |req|
      req.wait
      Wakame.log.debug("MySQL volume unmounted")
    }
    cond.wait

    require 'right_aws'
    ec2 = RightAws::Ec2.new(Wakame.config.aws_access_key, Wakame.config.aws_secret_key)
    ec2.describe_volumes.each do |volume|
      next unless volume[:aws_instance_id] == svc.cloud_host.agent_id && volume[:aws_device] == self.ebs_device

      @ebs_volume = volume[:aws_id]

      # detach volume
      res = ec2.detach_volume(@ebs_volume)
      Wakame.log.debug("detach_volume : #{res.inspect}")
      # waiting for available
      cond = ConditionalWait.new { |c|
        c.poll {
          res = ec2.describe_volumes([@ebs_volume])[0]
          res[:aws_status] == 'available'
        }
      }
      cond.wait

      # delete mysql-slave snapshot volume
      res = ec2.delete_volume(@ebs_volume)
      Wakame.log.debug("delete_volume : #{res.inspect}")
    end

    # unregister
    action.actor_request(svc.cloud_host.agent_id,
                         '/service_monitor/unregister',
                         svc.id).request

  end
end
