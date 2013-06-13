# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wakame-vdc-agents}
  s.version = "11.12.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{axsh Ltd.}]
  s.date = %q{2011-12-22}
  s.description = %q{Datacenter Hypervisor}
  s.email = [%q{dev@axsh.net}]
  s.executables = [%q{hva}, %q{sta}, %q{nsa}]
  s.files = [%q{config/path_resolver.rb}, %q{config/db/migrations/0001_v1110_origin.rb}, %q{config/initializers/passenger.rb}, %q{config/initializers/isono.rb}, %q{config/initializers/sequel.rb}, %q{lib/dcmgr.rb}, %q{lib/sinatra/accept_media_types.rb}, %q{lib/sinatra/url_for.rb}, %q{lib/sinatra/sequel_transaction.rb}, %q{lib/sinatra/static_assets.rb}, %q{lib/sinatra/rabbit.rb}, %q{lib/sinatra/respond_to.rb}, %q{lib/sinatra/lazy_auth.rb}, %q{lib/dcmgr/rack/request_logger.rb}, %q{lib/dcmgr/rack/run_initializer.rb}, %q{lib/dcmgr/version.rb}, %q{lib/dcmgr/scheduler/host_node/least_usage.rb}, %q{lib/dcmgr/scheduler/host_node/per_instance.rb}, %q{lib/dcmgr/scheduler/host_node/specify_node.rb}, %q{lib/dcmgr/scheduler/host_node/exclude_same.rb}, %q{lib/dcmgr/scheduler/host_node/find_first.rb}, %q{lib/dcmgr/scheduler/network/per_instance.rb}, %q{lib/dcmgr/scheduler/network/vif_template.rb}, %q{lib/dcmgr/scheduler/network/flat_single.rb}, %q{lib/dcmgr/scheduler/network/nat_one_to_one.rb}, %q{lib/dcmgr/scheduler/storage_node/least_usage.rb}, %q{lib/dcmgr/scheduler/storage_node/find_first.rb}, %q{lib/dcmgr/scheduler.rb}, %q{lib/dcmgr/endpoints/metadata.rb}, %q{lib/dcmgr/endpoints/errors.rb}, %q{lib/dcmgr/endpoints/core_api.rb}, %q{lib/dcmgr/tags.rb}, %q{lib/dcmgr/vnet.rb}, %q{lib/dcmgr/models/ip_lease.rb}, %q{lib/dcmgr/models/volume_snapshot.rb}, %q{lib/dcmgr/models/tag_mapping.rb}, %q{lib/dcmgr/models/instance_spec.rb}, %q{lib/dcmgr/models/mac_lease.rb}, %q{lib/dcmgr/models/vlan_lease.rb}, %q{lib/dcmgr/models/host_node.rb}, %q{lib/dcmgr/models/host_node_vnet.rb}, %q{lib/dcmgr/models/security_group_rule.rb}, %q{lib/dcmgr/models/base_new.rb}, %q{lib/dcmgr/models/instance_security_group.rb}, %q{lib/dcmgr/models/account.rb}, %q{lib/dcmgr/models/dhcp_range.rb}, %q{lib/dcmgr/models/security_group.rb}, %q{lib/dcmgr/models/frontend_system.rb}, %q{lib/dcmgr/models/image.rb}, %q{lib/dcmgr/models/instance.rb}, %q{lib/dcmgr/models/volume.rb}, %q{lib/dcmgr/models/tag.rb}, %q{lib/dcmgr/models/account_resource.rb}, %q{lib/dcmgr/models/physical_network.rb}, %q{lib/dcmgr/models/storage_node.rb}, %q{lib/dcmgr/models/hostname_lease.rb}, %q{lib/dcmgr/models/network.rb}, %q{lib/dcmgr/models/network_service.rb}, %q{lib/dcmgr/models/network_vif.rb}, %q{lib/dcmgr/models/request_log.rb}, %q{lib/dcmgr/models/base.rb}, %q{lib/dcmgr/models/quota.rb}, %q{lib/dcmgr/models/history.rb}, %q{lib/dcmgr/models/ssh_key_pair.rb}, %q{lib/dcmgr/logger.rb}, %q{lib/dcmgr/drivers/iscsi_target.rb}, %q{lib/dcmgr/drivers/lxc.rb}, %q{lib/dcmgr/drivers/comstar.rb}, %q{lib/dcmgr/drivers/linux_iscsi.rb}, %q{lib/dcmgr/drivers/iijgio_storage.rb}, %q{lib/dcmgr/drivers/raw.rb}, %q{lib/dcmgr/drivers/backing_store.rb}, %q{lib/dcmgr/drivers/s3_storage.rb}, %q{lib/dcmgr/drivers/storage_initiator.rb}, %q{lib/dcmgr/drivers/zfs.rb}, %q{lib/dcmgr/drivers/snapshot_storage.rb}, %q{lib/dcmgr/drivers/hypervisor.rb}, %q{lib/dcmgr/drivers/kvm.rb}, %q{lib/dcmgr/drivers/local_storage.rb}, %q{lib/dcmgr/drivers/sun_iscsi.rb}, %q{lib/dcmgr/rubygems.rb}, %q{lib/dcmgr/storage_service.rb}, %q{lib/dcmgr/rpc/sta_handler.rb}, %q{lib/dcmgr/rpc/hva_handler.rb}, %q{lib/dcmgr/messaging_client.rb}, %q{lib/dcmgr/helpers/ec2_metadata_helper.rb}, %q{lib/dcmgr/helpers/nic_helper.rb}, %q{lib/dcmgr/helpers/cli_helper.rb}, %q{lib/dcmgr/helpers/snapshot_storage_helper.rb}, %q{lib/dcmgr/node_modules/hva_collector.rb}, %q{lib/dcmgr/node_modules/instance_ha.rb}, %q{lib/dcmgr/node_modules/scheduler.rb}, %q{lib/dcmgr/node_modules/sta_tgt_initializer.rb}, %q{lib/dcmgr/node_modules/sta_collector.rb}, %q{lib/dcmgr/node_modules/service_openflow.rb}, %q{lib/dcmgr/node_modules/instance_monitor.rb}, %q{lib/dcmgr/node_modules/service_netfilter.rb}, %q{lib/dcmgr/vnet/netfilter/chain.rb}, %q{lib/dcmgr/vnet/netfilter/controller.rb}, %q{lib/dcmgr/vnet/netfilter/task_manager.rb}, %q{lib/dcmgr/vnet/netfilter/ebtables_rule.rb}, %q{lib/dcmgr/vnet/netfilter/iptables_rule.rb}, %q{lib/dcmgr/vnet/netfilter/cache.rb}, %q{lib/dcmgr/vnet/openflow/arp_handler.rb}, %q{lib/dcmgr/vnet/openflow/icmp_handler.rb}, %q{lib/dcmgr/vnet/openflow/constants.rb}, %q{lib/dcmgr/vnet/openflow/controller.rb}, %q{lib/dcmgr/vnet/openflow/datapath.rb}, %q{lib/dcmgr/vnet/openflow/flow.rb}, %q{lib/dcmgr/vnet/openflow/network.rb}, %q{lib/dcmgr/vnet/openflow/port.rb}, %q{lib/dcmgr/vnet/openflow/switch.rb}, %q{lib/dcmgr/vnet/openflow/ovs_ofctl.rb}, %q{lib/dcmgr/vnet/openflow/packet_handler.rb}, %q{lib/dcmgr/vnet/openflow/service_base.rb}, %q{lib/dcmgr/vnet/openflow/service_dhcp.rb}, %q{lib/dcmgr/vnet/openflow/service_dns.rb}, %q{lib/dcmgr/vnet/openflow/service_gateway.rb}, %q{lib/dcmgr/vnet/openflow/service_metadata.rb}, %q{lib/dcmgr/vnet/factories.rb}, %q{lib/dcmgr/vnet/tasks/drop_ip_from_anywhere.rb}, %q{lib/dcmgr/vnet/tasks/accept_related_established.rb}, %q{lib/dcmgr/vnet/tasks/accept_wakame_dns_only.rb}, %q{lib/dcmgr/vnet/tasks/drop_arp_to_host.rb}, %q{lib/dcmgr/vnet/tasks/static_nat.rb}, %q{lib/dcmgr/vnet/tasks/drop_arp_forwarding.rb}, %q{lib/dcmgr/vnet/tasks/accept_arp_to_host.rb}, %q{lib/dcmgr/vnet/tasks/accept_ip_from_gateway.rb}, %q{lib/dcmgr/vnet/tasks/accept_arp_from_friends.rb}, %q{lib/dcmgr/vnet/tasks/security_group.rb}, %q{lib/dcmgr/vnet/tasks/accept_wakame_dhcp_only.rb}, %q{lib/dcmgr/vnet/tasks/accept_arp_broadcast.rb}, %q{lib/dcmgr/vnet/tasks/accept_ip_from_friends.rb}, %q{lib/dcmgr/vnet/tasks/translate_metadata_address.rb}, %q{lib/dcmgr/vnet/tasks/accept_all_dns.rb}, %q{lib/dcmgr/vnet/tasks/drop_ip_spoofing.rb}, %q{lib/dcmgr/vnet/tasks/drop_mac_spoofing.rb}, %q{lib/dcmgr/vnet/tasks/accept_arp_from_gateway.rb}, %q{lib/dcmgr/vnet/tasks/debug_iptables.rb}, %q{lib/dcmgr/vnet/tasks/exclude_from_nat.rb}, %q{lib/dcmgr/vnet/tasks/accept_ip_to_anywhere.rb}, %q{lib/dcmgr/vnet/isolators/by_securitygroup.rb}, %q{lib/dcmgr/vnet/isolators/dummy.rb}, %q{lib/dcmgr/cli/vlan.rb}, %q{lib/dcmgr/cli/storage.rb}, %q{lib/dcmgr/cli/spec.rb}, %q{lib/dcmgr/cli/errors.rb}, %q{lib/dcmgr/cli/security_group.rb}, %q{lib/dcmgr/cli/host.rb}, %q{lib/dcmgr/cli/image.rb}, %q{lib/dcmgr/cli/tag.rb}, %q{lib/dcmgr/cli/keypair.rb}, %q{lib/dcmgr/cli/network.rb}, %q{lib/dcmgr/cli/base.rb}, %q{lib/dcmgr/cli/quota.rb}, %q{lib/ext/time.rb}, %q{Rakefile}, %q{LICENSE}, %q{NOTICE}, %q{config/hva.conf.example}, %q{config/nsa.conf.example}, %q{bin/hva}, %q{bin/sta}, %q{bin/nsa}]
  s.homepage = %q{http://wakame.jp/}
  s.require_paths = [%q{lib}]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = %q{1.8.23}
  s.summary = %q{Wakame-VDC: Agent modules}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<isono>, ["= 0.2.18"])
      s.add_runtime_dependency(%q<log4r>, [">= 0"])
      s.add_runtime_dependency(%q<extlib>, ["= 0.9.16"])
      s.add_runtime_dependency(%q<configuration>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_runtime_dependency(%q<ipaddress>, ["= 0.8.0"])
      s.add_runtime_dependency(%q<open4>, [">= 0"])
      s.add_development_dependency(%q<bacon>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<isono>, ["= 0.2.18"])
      s.add_dependency(%q<log4r>, [">= 0"])
      s.add_dependency(%q<extlib>, ["= 0.9.16"])
      s.add_dependency(%q<configuration>, [">= 0"])
      s.add_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_dependency(%q<ipaddress>, ["= 0.8.0"])
      s.add_dependency(%q<open4>, [">= 0"])
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<isono>, ["= 0.2.18"])
    s.add_dependency(%q<log4r>, [">= 0"])
    s.add_dependency(%q<extlib>, ["= 0.9.16"])
    s.add_dependency(%q<configuration>, [">= 0"])
    s.add_dependency(%q<ruby-hmac>, [">= 0"])
    s.add_dependency(%q<ipaddress>, ["= 0.8.0"])
    s.add_dependency(%q<open4>, [">= 0"])
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
