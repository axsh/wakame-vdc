# -*- coding: utf-8 -*-

require 'dcmgr/version'
require 'ext/time'

module Dcmgr

  class << self
    def conf
      @conf
    end

    def configure(config_path=nil, &blk)
      return self if @conf
      
      if config_path.is_a?(String)
        raise "Could not find configration file: #{config_path}" unless File.exists?(config_path)

        require 'configuration'
        code= <<-__END
        Configuration('global') do
          #{File.read(config_path)}
        end
        __END
        @conf = eval(code)
      else
        @conf = Configuration.for('global', &blk)
      end

      self
    end

    def run_initializers(*files)
      raise "Complete the configuration prior to run_initializers()." if @conf.nil?

      @files ||= []
      if files.length == 0
        @files << "*"
      else
      	@files = files
      end
      
      initializer_hooks.each { |n|
        n.call
      }
    end

    def initializer_hooks(&blk)
      @initializer_hooks ||= []
      if blk
        @initializer_hooks << blk
      end
      @initializer_hooks
    end
  end

  initializer_hooks {
    Dcmgr.class_eval {
      unless defined?(DCMGR_ROOT)
        DCMGR_ROOT = ENV['DCMGR_ROOT'] || File.expand_path('../../', __FILE__)
      end
    }
  }
  
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
  
  autoload :Logger, 'dcmgr/logger'
  

  require 'dcmgr/models/errors'
  module Models
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
    autoload :Volume, 'dcmgr/models/volume'
    autoload :VolumeSnapshot, 'dcmgr/models/volume_snapshot'
    autoload :SecurityGroup, 'dcmgr/models/security_group'
    autoload :SecurityGroupRule, 'dcmgr/models/security_group_rule'
    autoload :InstanceSpec, 'dcmgr/models/instance_spec'
    autoload :NetworkVif, 'dcmgr/models/network_vif'
    autoload :Network, 'dcmgr/models/network'
    autoload :IpLease, 'dcmgr/models/ip_lease'
    autoload :InstanceSecurityGroup, 'dcmgr/models/instance_security_group'
    autoload :SshKeyPair, 'dcmgr/models/ssh_key_pair'
    autoload :History, 'dcmgr/models/history'
    autoload :HostnameLease, 'dcmgr/models/hostname_lease'
    autoload :MacLease, 'dcmgr/models/mac_lease'
    autoload :VlanLease, 'dcmgr/models/vlan_lease'
    autoload :Quota, 'dcmgr/models/quota'
    autoload :DhcpRange, 'dcmgr/models/dhcp_range'
    autoload :PhysicalNetwork, 'dcmgr/models/physical_network'
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
    end
  end

  module NodeModules
    autoload :StaCollector, 'dcmgr/node_modules/sta_collector'
    autoload :StaTgtInitializer, 'dcmgr/node_modules/sta_tgt_initializer'
    autoload :HvaCollector, 'dcmgr/node_modules/hva_collector'
    autoload :InstanceHA, 'dcmgr/node_modules/instance_ha'
    autoload :DebugOpenFlow, 'dcmgr/node_modules/debug_openflow'
    autoload :ServiceNetfilter, 'dcmgr/node_modules/service_netfilter'
    autoload :ServiceOpenFlow, 'dcmgr/node_modules/service_openflow'
    autoload :InstanceMonitor, 'dcmgr/node_modules/instance_monitor'
    autoload :Scheduler, 'dcmgr/node_modules/scheduler'
  end

  module Helpers
    autoload :CliHelper, 'dcmgr/helpers/cli_helper'
    autoload :NicHelper, 'dcmgr/helpers/nic_helper'
    autoload :SnapshotStorageHelper, 'dcmgr/helpers/snapshot_storage_helper'
  end

  autoload :Tags, 'dcmgr/tags'

  module Cli
    require 'dcmgr/cli/errors'

    autoload :Base, 'dcmgr/cli/base'
    autoload :Network, 'dcmgr/cli/network'
    autoload :Host, 'dcmgr/cli/host'
    autoload :Storage, 'dcmgr/cli/storage'
    autoload :AccountCli, 'dcmgr/cli/account'
    autoload :UsersCli, 'dcmgr/cli/user'
    autoload :Vlan, 'dcmgr/cli/vlan'
    autoload :Image, 'dcmgr/cli/image'
    autoload :KeyPair, 'dcmgr/cli/keypair'
    autoload :SecurityGroup, 'dcmgr/cli/security_group'
    autoload :Spec, 'dcmgr/cli/spec'
    autoload :Tag, 'dcmgr/cli/tag'
    autoload :Quota, 'dcmgr/cli/quota'

    module Debug
      autoload :Base, 'dcmgr/cli/debug/base'
      autoload :Vnet, 'dcmgr/cli/debug/vnet'
    end
  end

  module Rpc
    autoload :HvaHandler, 'dcmgr/rpc/hva_handler'
    autoload :StaHandler, 'dcmgr/rpc/sta_handler'
    autoload :KvmHelper, 'dcmgr/rpc/hva_handler'
  end

  # namespace for custom Rack HTTP middleware.
  module Rack
    autoload :RequestLogger, 'dcmgr/rack/request_logger'
    autoload :RunInitializer, 'dcmgr/rack/run_initializer'
  end
  
  module Drivers
    autoload :SnapshotStorage, 'dcmgr/drivers/snapshot_storage'
    autoload :LocalStorage, 'dcmgr/drivers/local_storage'
    autoload :S3Storage, 'dcmgr/drivers/s3_storage'
    autoload :IIJGIOStorage, 'dcmgr/drivers/iijgio_storage'
    autoload :Hypervisor, 'dcmgr/drivers/hypervisor'
    autoload :Kvm , 'dcmgr/drivers/kvm'
    autoload :Lxc , 'dcmgr/drivers/lxc'
    autoload :ESXi, 'dcmgr/drivers/esxi'
    autoload :BackingStore, 'dcmgr/drivers/backing_store'
    autoload :Zfs,          'dcmgr/drivers/zfs'
    autoload :Raw,          'dcmgr/drivers/raw'
    autoload :IscsiTarget,  'dcmgr/drivers/iscsi_target'
    autoload :SunIscsi,     'dcmgr/drivers/sun_iscsi'
    autoload :LinuxIscsi,   'dcmgr/drivers/linux_iscsi'
    autoload :Comstar,      'dcmgr/drivers/comstar'
    autoload :LocalStore,   'dcmgr/drivers/local_store.rb'
    autoload :LinuxLocalStore, 'dcmgr/drivers/linux_local_store.rb'
    autoload :ESXiLocalStore, 'dcmgr/drivers/esxi_local_store.rb'
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
    end
    module Network
      autoload :FlatSingle, 'dcmgr/scheduler/network/flat_single'
      autoload :NatOneToOne, 'dcmgr/scheduler/network/nat_one_to_one'
      autoload :VifTemplate, 'dcmgr/scheduler/network/vif_template'
      autoload :PerInstance, 'dcmgr/scheduler/network/per_instance'
    end
  end
  
  require 'dcmgr/vnet'
  module VNet
    autoload :ControllerFactory, 'dcmgr/vnet/factories'
    autoload :IsolatorFactory, 'dcmgr/vnet/factories'
    autoload :TaskFactory, 'dcmgr/vnet/factories'
    autoload :TaskManagerFactory, 'dcmgr/vnet/factories'
    
    module Netfilter
      autoload :NetfilterCache, 'dcmgr/vnet/netfilter/cache'
      autoload :NetfilterController, 'dcmgr/vnet/netfilter/controller'
      autoload :Chain, 'dcmgr/vnet/netfilter/chain'
      autoload :IptablesChain, 'dcmgr/vnet/netfilter/chain'
      autoload :EbtablesChain, 'dcmgr/vnet/netfilter/chain'
      autoload :EbtablesRule, 'dcmgr/vnet/netfilter/ebtables_rule'
      autoload :IptablesRule, 'dcmgr/vnet/netfilter/iptables_rule'
      autoload :NetfilterTaskManager, 'dcmgr/vnet/netfilter/task_manager'
      autoload :VNicProtocolTaskManager, 'dcmgr/vnet/netfilter/task_manager'
    end

    module OpenFlow
      autoload :Flow, 'dcmgr/vnet/openflow/flow'
      autoload :OpenFlowConstants, 'dcmgr/vnet/openflow/constants'
      autoload :OpenFlowController, 'dcmgr/vnet/openflow/controller'
      autoload :OpenFlowDatapath, 'dcmgr/vnet/openflow/datapath'
      autoload :OpenFlowNetwork, 'dcmgr/vnet/openflow/network'
      autoload :OpenFlowPort, 'dcmgr/vnet/openflow/port'
      autoload :OpenFlowSwitch, 'dcmgr/vnet/openflow/switch'
      autoload :OvsOfctl, 'dcmgr/vnet/openflow/ovs_ofctl'
      autoload :PacketHandler, 'dcmgr/vnet/openflow/packet_handler'
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
      autoload :AcceptIpFromGateway, 'dcmgr/vnet/tasks/accept_ip_from_gateway'
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
    end
    
    module Isolators
      autoload :BySecurityGroup, 'dcmgr/vnet/isolators/by_securitygroup'
      autoload :DummyIsolator, 'dcmgr/vnet/isolators/dummy'
    end
    
  end
  
end

module Ext
  autoload :BroadcastChannel, 'ext/broadcast_channel'
end
