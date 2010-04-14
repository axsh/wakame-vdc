
class MySQL_Master < Wakame::Service::Resource

  property :duplicable, {:default=>false}
  property :mysqld_server_id, {:default=>1}
  property :mysqld_port, {:default=>3306}

  property :mysqld_basedir
  property :ebs_volume
  property :ebs_device
  property :ebs_mount_option, {:default=>'noatime'}

  update_attribute :monitors, {
    '/service' => {
      :type=>:command,
      :cmdline=>'/usr/bin/mysqladmin --defaults-file=%{agent.root_path}/tmp/config/mysql_master/conf/my.cnf ping > /dev/null'
    }
  }

  def basedir
    File.join(Wakame.config.root_path, 'cluster', 'resources', 'mysql_master')
  end
  
  def mysqld_datadir
    #File.expand_path('data', mysqld_basedir)
    File.expand_path(mysqld_basedir)
  end

  def mysqld_log_bin
    File.expand_path('mysql-bin.log', mysqld_datadir)
  end

  def render_config(template)
    template.cp('init.d/mysql')
    template.render('conf/my.cnf')
    template.chmod("init.d/mysql", 0755)
  end


  def start(svc, action)
    # $ echo "GRANT REPLICATION SLAVE, REPLICATION CLIENT, RELOAD ON *.* TO 'wakame-repl'@'%' IDENTIFIED BY 'wakame-slave';" | /usr/bin/mysql -h#{mysql_master_ip} -uroot

    require 'right_aws'
    ec2 = RightAws::Ec2.new(Wakame.config.aws_access_key, Wakame.config.aws_secret_key)

    res = ec2.describe_volumes([self.ebs_volume])[0]
    ec2_instance_id = res[:aws_instance_id]
    if res[:aws_status] == 'in-use' && ec2_instance_id == svc.cloud_host.agent.vm_attr[:aws_instance_id]
       # Nothin to be done
    elsif res[:aws_status] == 'in-use' && ec2_instance_id != svc.cloud_host.agent.vm_attr[:aws_instance_id]
      ec2.detach_volume(self.ebs_volume)
      cond = ConditionalWait.new { |c|
        c.poll {
          res1 = ec2.describe_volumes([self.ebs_volume])[0]
          res1[:aws_status] == 'available'
        }
      }
      cond.wait

      ec2.attach_volume(self.ebs_volume, svc.cloud_host.agent.vm_attr[:aws_instance_id], self.ebs_device)
      cond = ConditionalWait.new { |c|
        c.poll {
          res1 = ec2.describe_volumes([self.ebs_volume])[0]
          res1[:aws_status] == 'in-use'
        }
      }
      cond.wait

    elsif res[:aws_status] == 'available'
      ec2.attach_volume(self.ebs_volume, svc.cloud_host.agent.vm_attr[:aws_instance_id], self.ebs_device)
      cond = ConditionalWait.new { |c|
        c.poll {
          res1 = ec2.describe_volumes([self.ebs_volume])[0]
          res1[:aws_status] == 'in-use'
        }
      }
      cond.wait
      
    end

    cond = ConditionalWait.new { |cond|
      cond.wait_event(Wakame::Event::ServiceOnline) { |event|
        event.instance_id == svc.id
      }
    }
    
    action.actor_request(svc.cloud_host.agent_id, '/system/mount', self.ebs_device, self.mysqld_datadir, self.ebs_mount_option) { |req|
      req.wait
      Wakame.log.debug("MySQL volume was mounted: #{self.mysqld_datadir}")
    }
    
    action.actor_request(svc.cloud_host.agent_id, '/daemon/start', 'mysql_master', 'init.d/mysql') { |req|
      req.wait
      Wakame.log.debug("MySQL process started")
    }
    cond.wait 
  end
  
  def stop(svc, action)
    cond = ConditionalWait.new { |cond|
      cond.wait_event(Wakame::Event::ServiceOffline) { |event|
        event.instance_id == svc.id
      }
    }
    
    action.actor_request(svc.cloud_host.agent_id, '/daemon/stop', 'mysql_master', 'init.d/mysql') { |req| req.wait }
    cond.wait
    action.actor_request(svc.cloud_host.agent_id, '/system/umount', self.mysqld_datadir) { |req|
      req.wait
      Wakame.log.debug("MySQL volume unmounted")
    }

    #TODO: Add detach_volume() AWS call here.
  end
end
