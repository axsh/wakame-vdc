# -*- coding: utf-8 -*-

require 'dcmgr/version'
require 'ext/time'
require 'dcmgr/initializer'

module Dcmgr
  DCMGR_ROOT = ENV['DCMGR_ROOT'] || File.expand_path('../../', __FILE__)

  include Dcmgr::Initializer

  # Add conf/initializers/*.rb loader
  initializer_hooks {
    initializers_root = File.expand_path('config/initializers', DCMGR_ROOT)

    @files.each { |file|
      if File.directory?(initializers_root)
        Dir.glob("#{initializers_root}/#{file}.rb") { |f|
          ::Kernel.load(f)
        }
      end
    }
  }

  module Constants
    autoload :Instance, 'dcmgr/constants/instance'
    autoload :Network, 'dcmgr/constants/network'
    autoload :Tag, 'dcmgr/constants/tag'
    autoload :LoadBalancer, 'dcmgr/constants/load_balancer'
    autoload :Image, 'dcmgr/constants/image'
    autoload :BackupObject, 'dcmgr/constants/backup_object'
    autoload :Volume, 'dcmgr/constants/volume'
    autoload :HostNode, 'dcmgr/constants/host_node'
    autoload :StorageNode, 'dcmgr/constants/storage_node'
    autoload :Alarm, 'dcmgr/constants/alarm'
  end
  Const = Constants

  autoload :Logger, 'dcmgr/logger'
  require 'dcmgr/configurations'
  module Configurations
    autoload :Hva, 'dcmgr/configurations/hva'
    autoload :Dcmgr, 'dcmgr/configurations/dcmgr'
    autoload :Sta, 'dcmgr/configurations/sta'
    autoload :Natbox, 'dcmgr/configurations/natbox'
    autoload :Nwmongw, 'dcmgr/configurations/nwmongw'
    autoload :Bksta, 'dcmgr/configurations/bksta'
  end

  require 'dcmgr/models/errors'
  module Models
    # Use yaml loader for serialization plugin.
    require 'yaml'
    autoload :BaseNew, 'dcmgr/models/base_new'
    autoload :Account, 'dcmgr/models/account'
    autoload :Tag, 'dcmgr/models/tag'
    autoload :TagMapping, 'dcmgr/models/tag_mapping'
    autoload :AccountResource, 'dcmgr/models/account_resource'
    autoload :Instance, 'dcmgr/models/instance'
    autoload :Image, 'dcmgr/models/image'
    autoload :HostNode, 'dcmgr/models/host_node'
    autoload :HostNodeVnet, 'dcmgr/models/host_node_vnet'
    autoload :RequestLog, 'dcmgr/models/request_log'
    autoload :FrontendSystem, 'dcmgr/models/frontend_system'
    autoload :StorageNode, 'dcmgr/models/storage_node'
    autoload :DcNetwork, 'dcmgr/models/dc_network'
    autoload :DhcpRange, 'dcmgr/models/dhcp_range'
    autoload :IpHandle, 'dcmgr/models/ip_handle'
    autoload :IpLease, 'dcmgr/models/ip_lease'
    autoload :IpPool, 'dcmgr/models/ip_pool'
    autoload :IpPoolDcNetwork, 'dcmgr/models/ip_pool_dc_network'
    autoload :Network, 'dcmgr/models/network'
    autoload :NetworkRoute, 'dcmgr/models/network_route'
    autoload :NetworkService, 'dcmgr/models/network_service'
    autoload :NetworkVif, 'dcmgr/models/network_vif'
    autoload :NetworkVifIpLease, 'dcmgr/models/network_vif_ip_lease'
    autoload :NetworkVifMonitor, 'dcmgr/models/network_vif_monitor'
    autoload :NetworkVifSecurityGroup, 'dcmgr/models/network_vif_security_group'
    autoload :NfsStorageNode, 'dcmgr/models/nfs_storage_node'
    autoload :NfsVolume, 'dcmgr/models/nfs_volume'
    autoload :MacLease, 'dcmgr/models/mac_lease'
    autoload :MacRange, 'dcmgr/models/mac_range'
    autoload :SecurityGroup, 'dcmgr/models/security_group'
    autoload :SecurityGroupReference, 'dcmgr/models/security_group_reference'
    autoload :SshKeyPair, 'dcmgr/models/ssh_key_pair'
    autoload :Volume, 'dcmgr/models/volume'
    autoload :VolumeSnapshot, 'dcmgr/models/volume_snapshot'
    autoload :History, 'dcmgr/models/history'
    autoload :HostnameLease, 'dcmgr/models/hostname_lease'
    autoload :VlanLease, 'dcmgr/models/vlan_lease'
    autoload :AccountingLog, 'dcmgr/models/accounting_log'
    autoload :LoadBalancer, 'dcmgr/models/load_balancer'
    autoload :LoadBalancerTarget, 'dcmgr/models/load_balancer_target'
    autoload :LoadBalancerInbound, 'dcmgr/models/load_balancer_inbound'
    autoload :BackupStorage, 'dcmgr/models/backup_storage'
    autoload :BackupObject, 'dcmgr/models/backup_object'
    autoload :InstanceMonitorAttr, 'dcmgr/models/instance_monitor_attr'
    autoload :QueuedJob, 'dcmgr/models/queued_job'
    autoload :Alarm, 'dcmgr/models/alarm'

    require 'dcmgr/models/log_storage/base'
    module LogStorage
      autoload :Base, 'dcmgr/models/log_storage/base'
      autoload :Cassandra, 'dcmgr/models/log_storage/cassandra'
    end

    autoload :ResourceLabel, 'dcmgr/models/resource_label'
    autoload :LocalVolume, 'dcmgr/models/local_volume'
    autoload :IscsiVolume, 'dcmgr/models/iscsi_volume'
    autoload :IscsiStorageNode, 'dcmgr/models/iscsi_storage_node'
  end

  module Endpoints
    # HTTP Header constants for request credentials.
    HTTP_X_VDC_REQUESTER_TOKEN='HTTP_X_VDC_REQUESTER_TOKEN'.freeze
    HTTP_X_VDC_ACCOUNT_UUID='HTTP_X_VDC_ACCOUNT_UUID'.freeze

    RACK_FRONTEND_SYSTEM_ID='dcmgr.frotend_system.id'.freeze

    autoload :Ec2Metadata, 'dcmgr/endpoints/metadata'
    autoload :Helpers, 'dcmgr/endpoints/helpers'
    autoload :ResponseGenerator, 'dcmgr/endpoints/response_generator'
    module V1203
      autoload :CoreAPI, 'dcmgr/endpoints/12.03/core_api'
      module Responses
      end
      module Helpers
        autoload :ResourceLabel, 'dcmgr/endpoints/12.03/helpers/resource_label'
      end
    end
  end

  module Metadata
    require 'dcmgr/metadata'

    autoload :AWS, 'dcmgr/metadata/aws'
  end

  module NodeModules
    autoload :StaCollector, 'dcmgr/node_modules/sta_collector'
    autoload :StaTgtInitializer, 'dcmgr/node_modules/sta_tgt_initializer'
    autoload :HvaCollector, 'dcmgr/node_modules/hva_collector'
    autoload :NatboxCollector, 'dcmgr/node_modules/natbox_collector'
    autoload :DebugOpenFlow, 'dcmgr/node_modules/debug_openflow'
    autoload :ServiceNatbox, 'dcmgr/node_modules/service_natbox'
    autoload :ServiceNetfilter, 'dcmgr/node_modules/service_netfilter'
    autoload :ServiceOpenFlow, 'dcmgr/node_modules/service_openflow'
    autoload :InstanceMonitor, 'dcmgr/node_modules/instance_monitor'
    autoload :Scheduler, 'dcmgr/node_modules/scheduler'
    autoload :Maintenance, 'dcmgr/node_modules/maintenance'
    autoload :EventHook, 'dcmgr/node_modules/event_hook'
    autoload :JobQueueProxy, 'dcmgr/node_modules/job_queue_proxy'
    autoload :JobQueueWorker, 'dcmgr/node_modules/job_queue_worker'
    autoload :ResourceCollector, 'dcmgr/node_modules/resource_collector'
    autoload :Monitor, 'dcmgr/node_modules/monitor'
    autoload :HaManager, 'dcmgr/node_modules/ha_manager'
    autoload :AlarmCollector, 'dcmgr/node_modules/alarm_collector'
    autoload :AlarmConfigUpdater, 'dcmgr/node_modules/alarm_config_updater'
  end

  module Helpers
    autoload :IndelibleApi, 'dcmgr/helpers/indelible_api'
    autoload :CliHelper, 'dcmgr/helpers/cli_helper'
    autoload :NicHelper, 'dcmgr/helpers/nic_helper'
    autoload :TemplateHelper, 'dcmgr/helpers/template_helper'
    autoload :SnapshotStorageHelper, 'dcmgr/helpers/snapshot_storage_helper'
    autoload :ByteUnit, 'dcmgr/helpers/byte_unit'
    autoload :Cgroup, 'dcmgr/helpers/cgroup'
    autoload :BlockDeviceHelper, 'dcmgr/helpers/block_device_helper'
  end

  autoload :Tags, 'dcmgr/tags'

  module SpecConvertor
    autoload :Base, 'dcmgr/spec_convertor'
    autoload :LoadBalancer, 'dcmgr/spec_convertor'
  end

  module Cli
    require 'dcmgr/cli/errors'

    autoload :Base, 'dcmgr/cli/base'
    autoload :Instance, 'dcmgr/cli/instance'
    autoload :Network, 'dcmgr/cli/network'
    autoload :Host, 'dcmgr/cli/host'
    autoload :Storage, 'dcmgr/cli/storage'
    autoload :Vlan, 'dcmgr/cli/vlan'
    autoload :Image, 'dcmgr/cli/image'
    autoload :KeyPair, 'dcmgr/cli/keypair'
    autoload :SecurityGroup, 'dcmgr/cli/security_group'
    autoload :ResourceGroup, 'dcmgr/cli/resource_group'
    autoload :BackupStorage, 'dcmgr/cli/backup_storage'
    autoload :BackupObject, 'dcmgr/cli/backup_object'
    autoload :MacRange, 'dcmgr/cli/mac_range'

    module Debug
      autoload :Base, 'dcmgr/cli/debug/base'
      autoload :Vnet, 'dcmgr/cli/debug/vnet'
    end
  end

  module Rpc
    autoload :HvaHandler, 'dcmgr/rpc/hva_handler'
    autoload :NatboxHandler, 'dcmgr/rpc/natbox_handler'
    autoload :StaHandler, 'dcmgr/rpc/sta_handler'
    autoload :HvaContext, 'dcmgr/rpc/hva_context'
    autoload :LocalStoreHandler, 'dcmgr/rpc/local_store_handler'
    autoload :MigrationHandler, 'dcmgr/rpc/migration_handler'
    autoload :WindowsHandler, 'dcmgr/rpc/windows_handler'
  end

  # namespace for custom Rack HTTP middleware.
  module Rack
    autoload :RequestLogger, 'dcmgr/rack/request_logger'
    autoload :RunInitializer, 'dcmgr/rack/run_initializer'
  end

  autoload :Task, 'dcmgr/task'

  module Drivers
    #
    # Backing store drivers
    #
    autoload :BackingStore, 'dcmgr/drivers/backing_store'
    autoload :Zfs,          'dcmgr/drivers/backing_store/zfs'
    autoload :Raw,          'dcmgr/drivers/backing_store/raw'
    autoload :Indelible,    'dcmgr/drivers/backing_store/indelible'

    #
    # Backup storage drivers
    #
    autoload :BackupStorage,    'dcmgr/drivers/backup_storage'
    autoload :Webdav,           'dcmgr/drivers/backup_storage/webdav'
    autoload :IndelibleStorage, 'dcmgr/drivers/backup_storage/indelible_storage'
    autoload :LocalStorage,     'dcmgr/drivers/backup_storage/local_storage'

    #
    # Hypervisor drivers
    #
    autoload :Hypervisor,      'dcmgr/drivers/hypervisor'
    autoload :DummyHypervisor, 'dcmgr/drivers/hypervisor/dummy_hypervisor'
    autoload :ESXi,            'dcmgr/drivers/hypervisor/esxi'
    autoload :LinuxHypervisor, 'dcmgr/drivers/hypervisor/linux_hypervisor'
    autoload :Kvm ,            'dcmgr/drivers/hypervisor/linux_hypervisor/kvm'
    autoload :LinuxContainer,  'dcmgr/drivers/hypervisor/linux_hypervisor/linux_container'
    autoload :Lxc ,            'dcmgr/drivers/hypervisor/linux_hypervisor/linux_container/lxc'
    autoload :Openvz,          'dcmgr/drivers/hypervisor/linux_hypervisor/linux_container/openvz'

    #
    # Storage target drivers
    #
    autoload :StorageTarget,  'dcmgr/drivers/storage_target'
    autoload :IscsiTarget,    'dcmgr/drivers/storage_target/iscsi_target'
    autoload :IndelibleIscsi, 'dcmgr/drivers/storage_target/iscsi_target/indelible_iscsi'
    autoload :SunIscsi,       'dcmgr/drivers/storage_target/iscsi_target/sun_iscsi'
    autoload :Tgt,            'dcmgr/drivers/storage_target/iscsi_target/tgt'
    autoload :Nfs,            'dcmgr/drivers/storage_target/nfs'

    #
    # Local store drivers
    #
    autoload :LocalStore,       'dcmgr/drivers/local_store.rb'
    autoload :DummyLocalStore,  'dcmgr/drivers/local_store/dummy_local_store.rb'
    autoload :ESXiLocalStore,   'dcmgr/drivers/local_store/esxi_local_store.rb'
    autoload :LinuxLocalStore,  'dcmgr/drivers/local_store/linux_local_store.rb'
    autoload :OpenvzLocalStore, 'dcmgr/drivers/local_store/openvz_local_store.rb'
    autoload :KvmLocalStore,    'dcmgr/drivers/local_store/kvm_local_store'

    autoload :Haproxy, 'dcmgr/drivers/haproxy'
    autoload :Stunnel, 'dcmgr/drivers/stunnel'
    autoload :Stud, 'dcmgr/drivers/stud'
    autoload :NetworkMonitoring, 'dcmgr/drivers/network_monitoring'
    autoload :Zabbix, 'dcmgr/drivers/zabbix'
    autoload :PublicZabbix, 'dcmgr/drivers/public_zabbix'
    autoload :Natbox, 'dcmgr/drivers/natbox'
    autoload :Fluent, 'dcmgr/drivers/fluent'
    autoload :HypervisorPolicy, 'dcmgr/drivers/hypervisor_policy'
  end

  autoload :StorageService, 'dcmgr/storage_service'

  require 'dcmgr/scheduler'
  module Scheduler
    module StorageNode
      autoload :FindFirst, 'dcmgr/scheduler/storage_node/find_first'
      autoload :LeastUsage, 'dcmgr/scheduler/storage_node/least_usage'
    end

    module HostNode
      autoload :FindFirst, 'dcmgr/scheduler/host_node/find_first'
      autoload :LeastUsage, 'dcmgr/scheduler/host_node/least_usage'
      autoload :ExcludeSame, 'dcmgr/scheduler/host_node/exclude_same'
      autoload :SpecifyNode, 'dcmgr/scheduler/host_node/specify_node'
      autoload :PipedRules, 'dcmgr/scheduler/host_node/piped_rules'
      module Rules
        autoload :RequestParamToGroup, 'dcmgr/scheduler/host_node/rules/request_param_to_group'
        autoload :LeastUsageBy, 'dcmgr/scheduler/host_node/rules/least_usage_by'
        autoload :ScatterBy, 'dcmgr/scheduler/host_node/rules/scatter_by'
      end
    end

    module Network
      autoload :FlatSingle, 'dcmgr/scheduler/network/flat_single'
      autoload :NatOneToOne, 'dcmgr/scheduler/network/nat_one_to_one'
      autoload :VifTemplate, 'dcmgr/scheduler/network/vif_template'
      autoload :VifParamTemplate, 'dcmgr/scheduler/network/vif_param_template'
      autoload :PerInstance, 'dcmgr/scheduler/network/per_instance'
      autoload :VifsRequestParam, 'dcmgr/scheduler/network/vifs_request_param'
      autoload :RequestParamToGroup, 'dcmgr/scheduler/network/request_param_to_group'
      autoload :NetworkGroup, 'dcmgr/scheduler/network/network_group'
      autoload :SpecifyNetwork, 'dcmgr/scheduler/network/specify_network'
    end

    module MacAddress
      autoload :ByHostNodeGroup, 'dcmgr/scheduler/mac_address/by_host_node_group'
      autoload :Default, 'dcmgr/scheduler/mac_address/default'
      autoload :SpecifyMacAddress, 'dcmgr/scheduler/mac_address/specify_mac_address'
    end

    module IPAddress
      autoload :Incremental, 'dcmgr/scheduler/ip_address/incremental'
      autoload :SpecifyIP, 'dcmgr/scheduler/ip_address/specify_ip'
    end

    NAMESPACES=[HostNode, StorageNode, Network, MacAddress, IPAddress]
  end

  require 'dcmgr/vnet'
  module VNet
    autoload :TaskManagerFactory, 'dcmgr/vnet/factories'

    module NetworkModes
      autoload :SecurityGroup, 'dcmgr/vnet/network_modes/security_group'
      autoload :PassThrough, 'dcmgr/vnet/network_modes/passthrough'
      autoload :L2Overlay, 'dcmgr/vnet/network_modes/l2overlay'
    end

    module Netfilter
      autoload :NetfilterCache, 'dcmgr/vnet/netfilter/cache'
      autoload :Chain, 'dcmgr/vnet/netfilter/chain'
      autoload :IptablesChain, 'dcmgr/vnet/netfilter/chain'
      autoload :EbtablesChain, 'dcmgr/vnet/netfilter/chain'
      autoload :EbtablesRule, 'dcmgr/vnet/netfilter/ebtables_rule'
      autoload :IptablesRule, 'dcmgr/vnet/netfilter/iptables_rule'
      autoload :NetfilterTaskManager, 'dcmgr/vnet/netfilter/task_manager'
      autoload :VNicProtocolTaskManager, 'dcmgr/vnet/netfilter/task_manager'
      autoload :CacheDumper, 'dcmgr/vnet/netfilter/cache_dumper'
    end

    module OpenFlow
      autoload :ArpHandler, 'dcmgr/vnet/openflow/arp_handler'
      autoload :IcmpHandler, 'dcmgr/vnet/openflow/icmp_handler'
      autoload :Flow, 'dcmgr/vnet/openflow/flow'
      autoload :FlowGroup, 'dcmgr/vnet/openflow/flow_group'
      autoload :NetworkPhysical, 'dcmgr/vnet/openflow/network_physical'
      autoload :NetworkVirtual, 'dcmgr/vnet/openflow/network_virtual'
      autoload :OpenFlowConstants, 'dcmgr/vnet/openflow/constants'
      autoload :OpenFlowController, 'dcmgr/vnet/openflow/controller'
      autoload :OpenFlowDatapath, 'dcmgr/vnet/openflow/datapath'
      autoload :OpenFlowNetwork, 'dcmgr/vnet/openflow/network'
      autoload :OpenFlowPort, 'dcmgr/vnet/openflow/port'
      autoload :OpenFlowSwitch, 'dcmgr/vnet/openflow/switch'
      autoload :OvsOfctl, 'dcmgr/vnet/openflow/ovs_ofctl'
      autoload :PacketHandler, 'dcmgr/vnet/openflow/packet_handler'
      autoload :PortPhysical, 'dcmgr/vnet/openflow/port_physical'
      autoload :PortVirtual, 'dcmgr/vnet/openflow/port_virtual'
      autoload :ServiceBase, 'dcmgr/vnet/openflow/service_base'
      autoload :ServiceDhcp, 'dcmgr/vnet/openflow/service_dhcp'
      autoload :ServiceDns, 'dcmgr/vnet/openflow/service_dns'
      autoload :ServiceGateway, 'dcmgr/vnet/openflow/service_gateway'
      autoload :ServiceMetadata, 'dcmgr/vnet/openflow/service_metadata'
    end

    module Tasks
      autoload :AcceptAllDNS, 'dcmgr/vnet/tasks/accept_all_dns'
      autoload :AcceptArpBroadcast, 'dcmgr/vnet/tasks/accept_arp_broadcast'
      autoload :AcceptARPFromFriends, 'dcmgr/vnet/tasks/accept_arp_from_friends'
      autoload :AcceptARPFromGateway, 'dcmgr/vnet/tasks/accept_arp_from_gateway'
      autoload :AcceptARPFromDNS, 'dcmgr/vnet/tasks/accept_arp_from_dns'
      autoload :AcceptARPToHost, 'dcmgr/vnet/tasks/accept_arp_to_host'
      autoload :AcceptIpFromFriends, 'dcmgr/vnet/tasks/accept_ip_from_friends'
      autoload :AcceptIpToAnywhere, 'dcmgr/vnet/tasks/accept_ip_to_anywhere'
      autoload :AcceptRelatedEstablished, 'dcmgr/vnet/tasks/accept_related_established'
      autoload :AcceptTcpRelatedEstablished, 'dcmgr/vnet/tasks/accept_related_established'
      autoload :AcceptUdpEstablished, 'dcmgr/vnet/tasks/accept_related_established'
      autoload :AcceptIcmpRelatedEstablished, 'dcmgr/vnet/tasks/accept_related_established'
      autoload :AcceptWakameDHCPOnly, 'dcmgr/vnet/tasks/accept_wakame_dhcp_only'
      autoload :AcceptWakameDNSOnly, 'dcmgr/vnet/tasks/accept_wakame_dns_only'
      autoload :DebugIptables, 'dcmgr/vnet/tasks/debug_iptables'
      autoload :DropArpForwarding, 'dcmgr/vnet/tasks/drop_arp_forwarding'
      autoload :DropArpToHost, 'dcmgr/vnet/tasks/drop_arp_to_host'
      autoload :DropIpFromAnywhere, 'dcmgr/vnet/tasks/drop_ip_from_anywhere'
      autoload :DropIpSpoofing, 'dcmgr/vnet/tasks/drop_ip_spoofing'
      autoload :DropMacSpoofing, 'dcmgr/vnet/tasks/drop_mac_spoofing'
      autoload :ExcludeFromNat, 'dcmgr/vnet/tasks/exclude_from_nat'
      autoload :ExcludeFromNatIpSet, 'dcmgr/vnet/tasks/exclude_from_nat'
      autoload :SecurityGroup, 'dcmgr/vnet/tasks/security_group'
      autoload :StaticNat, 'dcmgr/vnet/tasks/static_nat'
      autoload :StaticNatLog, 'dcmgr/vnet/tasks/static_nat'
      autoload :TranslateMetadataAddress, 'dcmgr/vnet/tasks/translate_metadata_address'
      autoload :TranslateLoggingAddress, 'dcmgr/vnet/tasks/translate_logging_address'
      autoload :AcceptGARPFromGateway, 'dcmgr/vnet/tasks/accept_garp_from_gateway'
      autoload :AcceptARPReply, 'dcmgr/vnet/tasks/accept_arp_reply'
    end

  end

  require 'dcmgr/messaging'
  module Messaging
    autoload :LoadBalancer, 'dcmgr/messaging/load_balancer'
    autoload :JobQueue, 'dcmgr/messaging/job_queue'
  end

  autoload :TextLog, 'dcmgr/text_log'

  module Monitor
    autoload :ResourceCapture, 'dcmgr/monitor/resource_capture'
    autoload :Notification, 'dcmgr/monitor/notification'
  end
end

module Ext
  autoload :BroadcastChannel, 'ext/broadcast_channel'
end
