class Wakame::Actor::MySQL
  include Wakame::Actor

  # for Amazon EC2
  def take_master_snapshot(opt_map)
    Wakame.log.debug("take_master_snapshot: #{opt_map.inspect}")

    mysql_client = "/usr/bin/mysql -h#{opt_map[:master_ip]} -P#{opt_map[:master_port]} -u#{opt_map[:repl_user]} -p#{opt_map[:repl_pass]} -s"

    # master info
    Wakame::Util.exec("echo 'FLUSH TABLES WITH READ LOCK;' | #{mysql_client}")
    master_status = `echo show master status | #{mysql_client}`.to_s.split(/\t/)[0..1]

    # mysql/data/master.info
    master_infos = []
    master_infos << 14
    master_infos << master_status[0]
    master_infos << master_status[1]
    master_infos << opt_map[:master_ip]
    master_infos << opt_map[:repl_user]
    master_infos << opt_map[:repl_pass]
    master_infos << opt_map[:master_port]
    master_infos << 60
    master_infos << 0
    master_infos << ""
    master_infos << ""
    master_infos << ""
    master_infos << ""
    master_infos << ""
    master_infos << ""
    Wakame.log.debug(master_infos)

    master_info = File.expand_path('master.info', opt_map[:master_mysqld_datadir])
    Wakame.log.debug("master_info : #{master_info}")
    file = File.new(master_info, "w")
    file.puts(master_infos.join("\n"))
    file.chmod(0664)
    file.close

    require 'fileutils'
    FileUtils.chown('mysql', 'mysql', master_info)
    Wakame::Util.exec("/bin/sync")
    sleep 1.0

    #
    require 'right_aws'
    ec2 = RightAws::Ec2.new(opt_map[:aws_access_key], opt_map[:aws_secret_key])

    volume_map = ec2.describe_volumes([opt_map[:master_ebs_volume]])[0]
    Wakame.log.debug("describe_volume(#{opt_map[:master_ebs_volume]}): #{volume_map.inspect}")
    if volume_map[:aws_status] == 'in-use'
      # Nothin to be done
    else
      Wakame.log.debug("The EBS volume(slave) is not ready to attach: #{opt_map[:master_ebs_volume]}")
      return
    end

    # create_snapshot
    snapshot_map = ec2.create_snapshot(opt_map[:master_ebs_volume])
    Wakame.log.debug("create_snapshot #{snapshot_map.inspect}")
    cond = ConditionalWait.new { |c|
      c.poll {
        snapshot_map = ec2.describe_snapshots([snapshot_map[:aws_id]])[0]
        Wakame.log.debug("describe_snapshot #{snapshot_map.inspect}")
        Wakame::Util.exec("/bin/sync")
        snapshot_map[:aws_status] == "completed"
      }
    }
    cond.wait

    # unlock
    Wakame::Util.exec("echo 'UNLOCK TABLES;' | #{mysql_client}")

    # create volume from snapshot
    created_volume_from_snapshot_map = ec2.create_volume(snapshot_map[:aws_id], volume_map[:aws_size], volume_map[:zone])
    Wakame.log.debug("create_volume_from_snapshot #{created_volume_from_snapshot_map}")
    cond = ConditionalWait.new { |c|
      c.poll {
        volume_map = ec2.describe_volumes([created_volume_from_snapshot_map[:aws_id]])[0]
        Wakame.log.debug("describe_volume: #{volume_map.inspect}")
        Wakame::Util.exec("/bin/sync")
        volume_map[:aws_status] == "available"
      }
    }
    cond.wait

    # delete_snapshot
    delete_map = ec2.delete_snapshot(snapshot_map[:aws_id])
    Wakame.log.debug("delete_map #{delete_map.inspect}")

    # attach_volume
    Wakame.log.debug("attach-target #{volume_map.inspect}")
    attach_volume_map = ec2.attach_volume(volume_map[:aws_id], agent.agent_id, opt_map[:ebs_device])
    Wakame.log.debug("attach_volume_map #{attach_volume_map.inspect}")
    cond = ConditionalWait.new { |c|
      c.poll {
        volume_map = ec2.describe_volumes([attach_volume_map[:aws_id]])[0]
        Wakame.log.debug("describe_volume #{volume_map.inspect}")
        Wakame::Util.exec("/bin/sync")
        volume_map[:aws_status] == "in-use"
      }
    }
    cond.wait

  end
end
