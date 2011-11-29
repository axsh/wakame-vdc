# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wakame-vdc-agents}
  s.version = "11.06.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["axsh Ltd."]
  s.date = %q{2011-06-30}
  s.description = %q{}
  s.email = ["dev@axsh.net"]
  s.executables = ["hva", "sta", "nsa", "ofc"]
  s.files = ["config/path_resolver.rb", "config/initializers/passenger.rb", "config/initializers/isono.rb", "config/initializers/sequel.rb", "lib/dcmgr.rb", "lib/sinatra/accept_media_types.rb", "lib/sinatra/url_for.rb", "lib/sinatra/sequel_transaction.rb", "lib/sinatra/static_assets.rb", "lib/sinatra/rabbit.rb", "lib/sinatra/respond_to.rb", "lib/sinatra/lazy_auth.rb", "lib/dcmgr/rack/request_logger.rb", "lib/dcmgr/rack/run_initializer.rb", "lib/dcmgr/stm/snapshot_context.rb", "lib/dcmgr/stm/volume_context.rb", "lib/dcmgr/stm/instance.rb", "lib/dcmgr/version.rb", "lib/dcmgr/scheduler/find_random.rb", "lib/dcmgr/scheduler/find_last.rb", "lib/dcmgr/scheduler.rb", "lib/dcmgr/endpoints/metadata.rb", "lib/dcmgr/endpoints/errors.rb", "lib/dcmgr/endpoints/core_api_mock.rb", "lib/dcmgr/endpoints/core_api.rb", "lib/dcmgr/tags.rb", "lib/dcmgr/models/ip_lease.rb", "lib/dcmgr/models/instance_netfilter_group.rb", "lib/dcmgr/models/volume_snapshot.rb", "lib/dcmgr/models/storage_pool.rb", "lib/dcmgr/models/netfilter_rule.rb", "lib/dcmgr/models/tag_mapping.rb", "lib/dcmgr/models/instance_spec.rb", "lib/dcmgr/models/host_pool.rb", "lib/dcmgr/models/instance_nic.rb", "lib/dcmgr/models/mac_lease.rb", "lib/dcmgr/models/vlan_lease.rb", "lib/dcmgr/models/base_new.rb", "lib/dcmgr/models/account.rb", "lib/dcmgr/models/frontend_system.rb", "lib/dcmgr/models/image.rb", "lib/dcmgr/models/instance.rb", "lib/dcmgr/models/volume.rb", "lib/dcmgr/models/netfilter_group.rb", "lib/dcmgr/models/tag.rb", "lib/dcmgr/models/account_resource.rb", "lib/dcmgr/models/hostname_lease.rb", "lib/dcmgr/models/network.rb", "lib/dcmgr/models/request_log.rb", "lib/dcmgr/models/base.rb", "lib/dcmgr/models/quota.rb", "lib/dcmgr/models/history.rb", "lib/dcmgr/models/ssh_key_pair.rb", "lib/dcmgr/logger.rb", "lib/dcmgr/drivers/lxc.rb", "lib/dcmgr/drivers/iijgio_storage.rb", "lib/dcmgr/drivers/s3_storage.rb", "lib/dcmgr/drivers/snapshot_storage.rb", "lib/dcmgr/drivers/hypervisor.rb", "lib/dcmgr/drivers/kvm.rb", "lib/dcmgr/rubygems.rb", "lib/dcmgr/storage_service.rb", "lib/dcmgr/rpc/hva_handler.rb", "lib/dcmgr/messaging_client.rb", "lib/dcmgr/helpers/nic_helper.rb", "lib/dcmgr/helpers/cli_helper.rb", "lib/dcmgr/node_modules/hva_collector.rb", "lib/dcmgr/node_modules/instance_ha.rb", "lib/dcmgr/node_modules/sta_collector.rb", "lib/dcmgr/node_modules/instance_monitor.rb", "lib/dcmgr/node_modules/openflow_controller.rb", "lib/dcmgr/node_modules/service_netfilter.rb", "lib/dcmgr/node_modules/service_openflow.rb", "lib/dcmgr/cli/vlan.rb", "lib/dcmgr/cli/storage.rb", "lib/dcmgr/cli/spec.rb", "lib/dcmgr/cli/errors.rb", "lib/dcmgr/cli/host.rb", "lib/dcmgr/cli/image.rb", "lib/dcmgr/cli/tag.rb", "lib/dcmgr/cli/keypair.rb", "lib/dcmgr/cli/network.rb", "lib/dcmgr/cli/base.rb", "lib/dcmgr/cli/quota.rb", "lib/dcmgr/cli/group.rb", "lib/ext/time.rb", "Rakefile", "LICENSE", "NOTICE", "config/hva.conf.example", "config/nsa.conf.example", "bin/hva", "bin/sta", "bin/nsa", "bin/ofc"]
  s.homepage = %q{http://wakame.jp/}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Datacenter management toolkit for IaaS Cloud: agent modules}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<isono>, ["= 0.2.3"])
      s.add_runtime_dependency(%q<log4r>, [">= 0"])
      s.add_runtime_dependency(%q<extlib>, ["= 0.9.15"])
      s.add_runtime_dependency(%q<configuration>, [">= 0"])
      s.add_runtime_dependency(%q<statemachine>, ["= 1.1.1"])
      s.add_runtime_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_runtime_dependency(%q<ipaddress>, ["= 0.7.0"])
      s.add_runtime_dependency(%q<open4>, [">= 0"])
      s.add_development_dependency(%q<bacon>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<isono>, ["= 0.2.3"])
      s.add_dependency(%q<log4r>, [">= 0"])
      s.add_dependency(%q<extlib>, ["= 0.9.15"])
      s.add_dependency(%q<configuration>, [">= 0"])
      s.add_dependency(%q<statemachine>, ["= 1.1.1"])
      s.add_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_dependency(%q<ipaddress>, ["= 0.7.0"])
      s.add_dependency(%q<open4>, [">= 0"])
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<isono>, ["= 0.2.3"])
    s.add_dependency(%q<log4r>, [">= 0"])
    s.add_dependency(%q<extlib>, ["= 0.9.15"])
    s.add_dependency(%q<configuration>, [">= 0"])
    s.add_dependency(%q<statemachine>, ["= 1.1.1"])
    s.add_dependency(%q<ruby-hmac>, [">= 0"])
    s.add_dependency(%q<ipaddress>, ["= 0.7.0"])
    s.add_dependency(%q<open4>, [">= 0"])
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
