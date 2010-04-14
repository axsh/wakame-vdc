# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wakame}
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["axsh co.,Ltd.", "Masahiro Fujiwara"]
  s.date = %q{2009-09-18}
  s.default_executable = %q{wakame}
  s.description = %q{}
  s.email = ["m-fujiwara@axsh.net"]
  s.executables = ["wakame"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "History.txt",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "app_generators/wakame/templates/README",
     "app_generators/wakame/templates/Rakefile",
     "app_generators/wakame/templates/bin/wakame-agent",
     "app_generators/wakame/templates/bin/wakame-master",
     "app_generators/wakame/templates/bin/wakameadm",
     "app_generators/wakame/templates/cluster/resources/markers/http_application_server.rb",
     "app_generators/wakame/templates/cluster/resources/markers/http_asset_server.rb",
     "app_generators/wakame/templates/cluster/resources/markers/http_server.rb",
     "app_generators/wakame/templates/config/boot.rb",
     "app_generators/wakame/templates/config/cluster.rb",
     "app_generators/wakame/templates/config/environments/common.rb",
     "app_generators/wakame/templates/config/environments/ec2.rb",
     "app_generators/wakame/templates/config/environments/stand_alone.rb",
     "app_generators/wakame/templates/config/init.d/wakame-agent",
     "app_generators/wakame/templates/config/init.d/wakame-master",
     "app_generators/wakame/wakame_generator.rb",
     "bin/wakame",
     "contrib/imagesetup.sh",
     "lib/ext/eventmachine.rb",
     "lib/ext/shellwords.rb",
     "lib/ext/uri.rb",
     "lib/wakame.rb",
     "lib/wakame/action.rb",
     "lib/wakame/action_manager.rb",
     "lib/wakame/actions/deploy_config.rb",
     "lib/wakame/actions/destroy_instances.rb",
     "lib/wakame/actions/launch_cluster.rb",
     "lib/wakame/actions/launch_vm.rb",
     "lib/wakame/actions/migrate_service.rb",
     "lib/wakame/actions/notify_child_changed.rb",
     "lib/wakame/actions/notify_parent_changed.rb",
     "lib/wakame/actions/propagate_resource.rb",
     "lib/wakame/actions/propagate_service.rb",
     "lib/wakame/actions/reload_service.rb",
     "lib/wakame/actions/scaleout_when_high_load.rb",
     "lib/wakame/actions/shutdown_cluster.rb",
     "lib/wakame/actions/shutdown_vm.rb",
     "lib/wakame/actions/start_service.rb",
     "lib/wakame/actions/stop_service.rb",
     "lib/wakame/actions/util.rb",
     "lib/wakame/actor.rb",
     "lib/wakame/actor/daemon.rb",
     "lib/wakame/actor/mysql.rb",
     "lib/wakame/actor/service_monitor.rb",
     "lib/wakame/actor/system.rb",
     "lib/wakame/agent.rb",
     "lib/wakame/amqp_client.rb",
     "lib/wakame/command.rb",
     "lib/wakame/command/action_status.rb",
     "lib/wakame/command/actor.rb",
     "lib/wakame/command/agent_status.rb",
     "lib/wakame/command/clone_service.rb",
     "lib/wakame/command/import_cluster_config.rb",
     "lib/wakame/command/launch_cluster.rb",
     "lib/wakame/command/launch_vm.rb",
     "lib/wakame/command/migrate_service.rb",
     "lib/wakame/command/propagate_resource.rb",
     "lib/wakame/command/propagate_service.rb",
     "lib/wakame/command/reload_service.rb",
     "lib/wakame/command/shutdown_cluster.rb",
     "lib/wakame/command/shutdown_vm.rb",
     "lib/wakame/command/start_service.rb",
     "lib/wakame/command/status.rb",
     "lib/wakame/command/stop_service.rb",
     "lib/wakame/command_queue.rb",
     "lib/wakame/configuration.rb",
     "lib/wakame/daemonize.rb",
     "lib/wakame/event.rb",
     "lib/wakame/event_dispatcher.rb",
     "lib/wakame/graph.rb",
     "lib/wakame/initializer.rb",
     "lib/wakame/instance_counter.rb",
     "lib/wakame/logger.rb",
     "lib/wakame/master.rb",
     "lib/wakame/monitor.rb",
     "lib/wakame/monitor/agent.rb",
     "lib/wakame/monitor/service.rb",
     "lib/wakame/packets.rb",
     "lib/wakame/queue_declare.rb",
     "lib/wakame/runner/administrator_command.rb",
     "lib/wakame/runner/agent.rb",
     "lib/wakame/runner/master.rb",
     "lib/wakame/scheduler.rb",
     "lib/wakame/service.rb",
     "lib/wakame/status_db.rb",
     "lib/wakame/template.rb",
     "lib/wakame/trigger.rb",
     "lib/wakame/triggers/instance_count_update.rb",
     "lib/wakame/triggers/load_history.rb",
     "lib/wakame/triggers/maintain_ssh_known_hosts.rb",
     "lib/wakame/triggers/shutdown_unused_vm.rb",
     "lib/wakame/util.rb",
     "lib/wakame/vm_manipulator.rb",
     "tasks/ec2.rake",
     "tests/cluster.json",
     "tests/setup_agent.rb",
     "tests/setup_master.rb",
     "tests/test_action_manager.rb",
     "tests/test_actor.rb",
     "tests/test_agent.rb",
     "tests/test_amqp_client.rb",
     "tests/test_graph.rb",
     "tests/test_master.rb",
     "tests/test_monitor.rb",
     "tests/test_scheduler.rb",
     "tests/test_service.rb",
     "tests/test_status_db.rb",
     "tests/test_template.rb",
     "tests/test_uri_amqp.rb",
     "tests/test_util.rb",
     "wakame_generators/resource/resource_generator.rb",
     "wakame_generators/resource/templates/apache_app/apache_app.rb",
     "wakame_generators/resource/templates/apache_app/conf/apache2.conf",
     "wakame_generators/resource/templates/apache_app/conf/envvars-app",
     "wakame_generators/resource/templates/apache_app/conf/system-app.conf",
     "wakame_generators/resource/templates/apache_app/conf/vh/aaa.test.conf",
     "wakame_generators/resource/templates/apache_app/init.d/apache2-app",
     "wakame_generators/resource/templates/apache_lb/apache_lb.rb",
     "wakame_generators/resource/templates/apache_lb/conf/apache2.conf",
     "wakame_generators/resource/templates/apache_lb/conf/envvars-lb",
     "wakame_generators/resource/templates/apache_lb/conf/system-lb.conf",
     "wakame_generators/resource/templates/apache_lb/conf/vh/aaa.test.conf",
     "wakame_generators/resource/templates/apache_lb/init.d/apache2-lb",
     "wakame_generators/resource/templates/apache_www/apache_www.rb",
     "wakame_generators/resource/templates/apache_www/conf/apache2.conf",
     "wakame_generators/resource/templates/apache_www/conf/envvars-www",
     "wakame_generators/resource/templates/apache_www/conf/system-www.conf",
     "wakame_generators/resource/templates/apache_www/conf/vh/aaa.test.conf",
     "wakame_generators/resource/templates/apache_www/init.d/apache2-www",
     "wakame_generators/resource/templates/ec2_elastic_ip/ec2_elastic_ip.rb",
     "wakame_generators/resource/templates/ec2_elb/ec2_elb.rb",
     "wakame_generators/resource/templates/memcached/conf/memcached.conf",
     "wakame_generators/resource/templates/memcached/init.d/memcached",
     "wakame_generators/resource/templates/memcached/memcached.rb",
     "wakame_generators/resource/templates/mysql_master/conf/my.cnf",
     "wakame_generators/resource/templates/mysql_master/init.d/mysql",
     "wakame_generators/resource/templates/mysql_master/mysql_master.rb",
     "wakame_generators/resource/templates/mysql_slave/conf/my.cnf",
     "wakame_generators/resource/templates/mysql_slave/init.d/mysql-slave",
     "wakame_generators/resource/templates/mysql_slave/mysql_slave.rb",
     "wakame_generators/resource/templates/nginx/conf/nginx.conf",
     "wakame_generators/resource/templates/nginx/conf/vh/aaa.test.conf",
     "wakame_generators/resource/templates/nginx/init.d/nginx",
     "wakame_generators/resource/templates/nginx/nginx.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://wakame.rubyforge.org/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{wakame}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A distributed service framework on top of Cloud environments.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<amqp>, [">= 0.6.0"])
      s.add_runtime_dependency(%q<right_aws>, [">= 1.10.0"])
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.8"])
      s.add_runtime_dependency(%q<rake>, [">= 0.8.7"])
      s.add_runtime_dependency(%q<log4r>, [">= 1.0.5"])
      s.add_runtime_dependency(%q<daemons>, [">= 1.0.10"])
      s.add_runtime_dependency(%q<rubigen>, [">= 1.5.2"])
      s.add_runtime_dependency(%q<open4>, [">= 0.9.6"])
      s.add_runtime_dependency(%q<jeweler>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<rack>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<thin>, [">= 1.2.2"])
      s.add_runtime_dependency(%q<json>, [">= 1.1.7"])
      s.add_runtime_dependency(%q<sequel>, [">= 3.2.0"])
    else
      s.add_dependency(%q<amqp>, [">= 0.6.0"])
      s.add_dependency(%q<right_aws>, [">= 1.10.0"])
      s.add_dependency(%q<eventmachine>, [">= 0.12.8"])
      s.add_dependency(%q<rake>, [">= 0.8.7"])
      s.add_dependency(%q<log4r>, [">= 1.0.5"])
      s.add_dependency(%q<daemons>, [">= 1.0.10"])
      s.add_dependency(%q<rubigen>, [">= 1.5.2"])
      s.add_dependency(%q<open4>, [">= 0.9.6"])
      s.add_dependency(%q<jeweler>, [">= 1.0.0"])
      s.add_dependency(%q<rack>, [">= 1.0.0"])
      s.add_dependency(%q<thin>, [">= 1.2.2"])
      s.add_dependency(%q<json>, [">= 1.1.7"])
      s.add_dependency(%q<sequel>, [">= 3.2.0"])
    end
  else
    s.add_dependency(%q<amqp>, [">= 0.6.0"])
    s.add_dependency(%q<right_aws>, [">= 1.10.0"])
    s.add_dependency(%q<eventmachine>, [">= 0.12.8"])
    s.add_dependency(%q<rake>, [">= 0.8.7"])
    s.add_dependency(%q<log4r>, [">= 1.0.5"])
    s.add_dependency(%q<daemons>, [">= 1.0.10"])
    s.add_dependency(%q<rubigen>, [">= 1.5.2"])
    s.add_dependency(%q<open4>, [">= 0.9.6"])
    s.add_dependency(%q<jeweler>, [">= 1.0.0"])
    s.add_dependency(%q<rack>, [">= 1.0.0"])
    s.add_dependency(%q<thin>, [">= 1.2.2"])
    s.add_dependency(%q<json>, [">= 1.1.7"])
    s.add_dependency(%q<sequel>, [">= 3.2.0"])
  end
end
