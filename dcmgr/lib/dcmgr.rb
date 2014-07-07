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
    module V1112
      autoload :CoreAPI, 'dcmgr/endpoints/11.12/core_api'
    end
    module V1203
      autoload :CoreAPI, 'dcmgr/endpoints/12.03/core_api'
      module Responses
      end
      module Helpers
        autoload :ResourceLabel, 'dcmgr/endpoints/12.03/helpers/resource_label'
      end
    end
  end

  module NodeModules
    autoload :StaCollector, 'dcmgr/node_modules/sta_collector'
    autoload :SGHandler, 'dcmgr/node_modules/sg_handler'
    autoload :StaTgtInitializer, 'dcmgr/node_modules/sta_tgt_initializer'
    autoload :HvaCollector, 'dcmgr/node_modules/hva_collector'
    autoload :NatboxCollector, 'dcmgr/node_modules/natbox_collector'
    autoload :InstanceHA, 'dcmgr/node_modules/instance_ha'
    autoload :DebugOpenFlow, 'dcmgr/node_modules/debug_openflow'
    autoload :ServiceNatbox, 'dcmgr/node_modules/service_natbox'
    autoload :LegacyNetfilter, 'dcmgr/node_modules/legacy_netfilter'
    autoload :ServiceOpenFlow, 'dcmgr/node_modules/service_openflow'
    autoload :InstanceMonitor, 'dcmgr/node_modules/instance_monitor'
    autoload :Scheduler, 'dcmgr/node_modules/scheduler'
    autoload :Maintenance, 'dcmgr/node_modules/maintenance'
    autoload :EventHook, 'dcmgr/node_modules/event_hook'
    autoload :JobQueueProxy, 'dcmgr/node_modules/job_queue_proxy'
    autoload :JobQueueWorker, 'dcmgr/node_modules/job_queue_worker'
    autoload :ResourceCollector, 'dcmgr/node_modules/resource_collector'
    autoload :Monitor, 'dcmgr/node_modules/monitor'
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
    autoload :NetfilterHandler, 'dcmgr/rpc/netfilter_handler'
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
    autoload :BackupStorage, 'dcmgr/drivers/backup_storage'
    autoload :LocalStorage, 'dcmgr/drivers/local_storage'
    autoload :S3Storage, 'dcmgr/drivers/s3_storage'
    autoload :IIJGIOStorage, 'dcmgr/drivers/iijgio_storage'
    autoload :Hypervisor, 'dcmgr/drivers/hypervisor'
    autoload :DummyHypervisor, 'dcmgr/drivers/dummy_hypervisor'
    autoload :LinuxHypervisor, 'dcmgr/drivers/linux_hypervisor'
    autoload :Kvm , 'dcmgr/drivers/kvm'
    autoload :Lxc , 'dcmgr/drivers/lxc'
    autoload :ESXi, 'dcmgr/drivers/esxi'
    autoload :Openvz, 'dcmgr/drivers/openvz'
    autoload :BackingStore, 'dcmgr/drivers/backing_store'
    autoload :Zfs,          'dcmgr/drivers/zfs'
    autoload :Raw,          'dcmgr/drivers/raw'
    autoload :IscsiTarget,  'dcmgr/drivers/iscsi_target'
    autoload :SunIscsi,     'dcmgr/drivers/sun_iscsi'
    autoload :Tgt,          'dcmgr/drivers/tgt'
    autoload :Comstar,      'dcmgr/drivers/comstar'
    autoload :LocalStore,   'dcmgr/drivers/local_store.rb'
    autoload :DummyLocalStore, 'dcmgr/drivers/dummy_local_store.rb'
    autoload :LinuxLocalStore, 'dcmgr/drivers/linux_local_store.rb'
    autoload :ESXiLocalStore, 'dcmgr/drivers/esxi_local_store.rb'
    autoload :OpenvzLocalStore, 'dcmgr/drivers/openvz_local_store.rb'
    autoload :Indelible, 'dcmgr/drivers/indelible'
    autoload :IndelibleIscsi, 'dcmgr/drivers/indelible_iscsi'
    autoload :IndelibleStorage, 'dcmgr/drivers/indelible_storage'
    autoload :Haproxy, 'dcmgr/drivers/haproxy'
    autoload :Webdav, 'dcmgr/drivers/webdav'
    autoload :Stunnel, 'dcmgr/drivers/stunnel'
    autoload :Stud, 'dcmgr/drivers/stud'
    autoload :NetworkMonitoring, 'dcmgr/drivers/network_monitoring'
    autoload :Zabbix, 'dcmgr/drivers/zabbix'
    autoload :PublicZabbix, 'dcmgr/drivers/public_zabbix'
    autoload :LinuxContainer, 'dcmgr/drivers/linux_container'
    autoload :Natbox, 'dcmgr/drivers/natbox'
    autoload :Fluent, 'dcmgr/drivers/fluent'
    autoload :HypervisorPolicy, 'dcmgr/drivers/hypervisor_policy'
    autoload :KvmLocalStore, 'dcmgr/drivers/kvm_local_store'
    autoload :StorageTarget, 'dcmgr/drivers/storage_target'
    autoload :Nfs, 'dcmgr/drivers/nfs'
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

  module EdgeNetworking
    autoload :TaskManagerFactory, 'dcmgr/edge_networking/factories'
    autoload :SGHandler, 'dcmgr/edge_networking/sg_handler.rb'
    autoload :VNicInitializer, 'dcmgr/edge_networking/vnic_initializer.rb'
    autoload :SGHandlerCommon, 'dcmgr/edge_networking/sg_handler_common.rb'
    autoload :CallIsonoPacketfilter, 'dcmgr/edge_networking/call_isono_packetfilter'
    autoload :PacketfilterService, 'dcmgr/edge_networking/packetfilter_service'

    module Netfilter
      require 'dcmgr/edge_networking/netfilter/network_mode'
      module NetworkModes
        autoload :SecurityGroup, 'dcmgr/edge_networking/netfilter/network_modes/security_group'
        autoload :PassThrough, 'dcmgr/edge_networking/netfilter/network_modes/passthrough'
        autoload :L2Overlay, 'dcmgr/edge_networking/netfilter/network_modes/l2overlay'
      end

      autoload :NetfilterService, 'dcmgr/edge_networking/netfilter/netfilter_service'
      autoload :NetfilterHandler, 'dcmgr/edge_networking/netfilter/netfilter_handler'
      autoload :Tasks, 'dcmgr/edge_networking/netfilter/tasks'
      autoload :Chains, 'dcmgr/edge_networking/netfilter/chains'
    end

    module LegacyNetfilter
      module NetworkModes
        autoload :SecurityGroup, 'dcmgr/edge_networking/network_modes/legacy_netfilter/security_group'
        autoload :PassThrough, 'dcmgr/edge_networking/network_modes/legacy_netfilter/passthrough'
        autoload :L2Overlay, 'dcmgr/edge_networking/network_modes/legacy_netfilter/l2overlay'
      end

      autoload :CacheDumper, 'dcmgr/edge_networking/legacy_netfilter/cache_dumper'
      autoload :NetfilterTaskManager, 'dcmgr/edge_networking/legacy_netfilter/task_manager'
      autoload :VNicProtocolTaskManager, 'dcmgr/edge_networking/legacy_netfilter/task_manager'
      autoload :IptablesChain, 'dcmgr/edge_networking/legacy_netfilter/chain'
      autoload :EbtablesChain, 'dcmgr/edge_networking/legacy_netfilter/chain'
      autoload :EbtablesRule, 'dcmgr/edge_networking/legacy_netfilter/ebtables_rule'
      autoload :IptablesRule, 'dcmgr/edge_networking/legacy_netfilter/iptables_rule'
      autoload :NetfilterCache, 'dcmgr/edge_networking/legacy_netfilter/cache'
      autoload :Chain, 'dcmgr/edge_networking/legacy_netfilter/chain'
    end

    module OpenFlow
      autoload :ArpHandler, 'dcmgr/edge_networking/openflow/arp_handler'
      autoload :IcmpHandler, 'dcmgr/edge_networking/openflow/icmp_handler'
      autoload :Flow, 'dcmgr/edge_networking/openflow/flow'
      autoload :FlowGroup, 'dcmgr/edge_networking/openflow/flow_group'
      autoload :NetworkPhysical, 'dcmgr/edge_networking/openflow/network_physical'
      autoload :NetworkVirtual, 'dcmgr/edge_networking/openflow/network_virtual'
      autoload :OpenFlowConstants, 'dcmgr/edge_networking/openflow/constants'
      autoload :OpenFlowController, 'dcmgr/edge_networking/openflow/controller'
      autoload :OpenFlowDatapath, 'dcmgr/edge_networking/openflow/datapath'
      autoload :OpenFlowNetwork, 'dcmgr/edge_networking/openflow/network'
      autoload :OpenFlowPort, 'dcmgr/edge_networking/openflow/port'
      autoload :OpenFlowSwitch, 'dcmgr/edge_networking/openflow/switch'
      autoload :OvsOfctl, 'dcmgr/edge_networking/openflow/ovs_ofctl'
      autoload :PacketHandler, 'dcmgr/edge_networking/openflow/packet_handler'
      autoload :PortPhysical, 'dcmgr/edge_networking/openflow/port_physical'
      autoload :PortVirtual, 'dcmgr/edge_networking/openflow/port_virtual'
      autoload :ServiceBase, 'dcmgr/edge_networking/openflow/service_base'
      autoload :ServiceDhcp, 'dcmgr/edge_networking/openflow/service_dhcp'
      autoload :ServiceDns, 'dcmgr/edge_networking/openflow/service_dns'
      autoload :ServiceGateway, 'dcmgr/edge_networking/openflow/service_gateway'
      autoload :ServiceMetadata, 'dcmgr/edge_networking/openflow/service_metadata'
    end

    module Tasks
      autoload :AcceptAllDNS, 'dcmgr/edge_networking/tasks/accept_all_dns'
      autoload :AcceptArpBroadcast, 'dcmgr/edge_networking/tasks/accept_arp_broadcast'
      autoload :AcceptARPFromFriends, 'dcmgr/edge_networking/tasks/accept_arp_from_friends'
      autoload :AcceptARPFromGateway, 'dcmgr/edge_networking/tasks/accept_arp_from_gateway'
      autoload :AcceptARPFromDNS, 'dcmgr/edge_networking/tasks/accept_arp_from_dns'
      autoload :AcceptARPToHost, 'dcmgr/edge_networking/tasks/accept_arp_to_host'
      autoload :AcceptIpFromFriends, 'dcmgr/edge_networking/tasks/accept_ip_from_friends'
      autoload :AcceptIpToAnywhere, 'dcmgr/edge_networking/tasks/accept_ip_to_anywhere'
      autoload :AcceptRelatedEstablished, 'dcmgr/edge_networking/tasks/accept_related_established'
      autoload :AcceptTcpRelatedEstablished, 'dcmgr/edge_networking/tasks/accept_related_established'
      autoload :AcceptUdpEstablished, 'dcmgr/edge_networking/tasks/accept_related_established'
      autoload :AcceptIcmpRelatedEstablished, 'dcmgr/edge_networking/tasks/accept_related_established'
      autoload :AcceptWakameDHCPOnly, 'dcmgr/edge_networking/tasks/accept_wakame_dhcp_only'
      autoload :AcceptWakameDNSOnly, 'dcmgr/edge_networking/tasks/accept_wakame_dns_only'
      autoload :DebugIptables, 'dcmgr/edge_networking/tasks/debug_iptables'
      autoload :DropArpForwarding, 'dcmgr/edge_networking/tasks/drop_arp_forwarding'
      autoload :DropArpToHost, 'dcmgr/edge_networking/tasks/drop_arp_to_host'
      autoload :DropIpFromAnywhere, 'dcmgr/edge_networking/tasks/drop_ip_from_anywhere'
      autoload :DropIpSpoofing, 'dcmgr/edge_networking/tasks/drop_ip_spoofing'
      autoload :DropMacSpoofing, 'dcmgr/edge_networking/tasks/drop_mac_spoofing'
      autoload :ExcludeFromNat, 'dcmgr/edge_networking/tasks/exclude_from_nat'
      autoload :ExcludeFromNatIpSet, 'dcmgr/edge_networking/tasks/exclude_from_nat'
      autoload :SecurityGroup, 'dcmgr/edge_networking/tasks/security_group'
      autoload :StaticNat, 'dcmgr/edge_networking/tasks/static_nat'
      autoload :StaticNatLog, 'dcmgr/edge_networking/tasks/static_nat'
      autoload :TranslateMetadataAddress, 'dcmgr/edge_networking/tasks/translate_metadata_address'
      autoload :TranslateLoggingAddress, 'dcmgr/edge_networking/tasks/translate_logging_address'
      autoload :AcceptGARPFromGateway, 'dcmgr/edge_networking/tasks/accept_garp_from_gateway'
      autoload :AcceptARPReply, 'dcmgr/edge_networking/tasks/accept_arp_reply'
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
