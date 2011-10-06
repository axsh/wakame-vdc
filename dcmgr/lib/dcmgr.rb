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
  
  module Models
    class InvalidUUIDError < StandardError; end
    class UUIDPrefixDuplication < StandardError; end
    autoload :Base, 'dcmgr/models/base'

    CREATE_TABLE_CLASSES=[:Account,:Tag,:TagMapping,:FrontendSystem,
                          :Image,:HostNode,:RequestLog,:Instance,
                          :NetfilterGroup, :NetfilterRule,
                          :StorageNode,:Volume,:VolumeSnapshot,
                          :InstanceNetfilterGroup,
                          :InstanceSpec, :InstanceNic, :Network, :IpLease,
                          :SshKeyPair, :History, :HostnameLease, :MacLease,
                          :VlanLease, :Quota
                         ].freeze
    autoload :BaseNew, 'dcmgr/models/base_new'
    autoload :Account, 'dcmgr/models/account'
    autoload :Tag, 'dcmgr/models/tag'
    autoload :TagMapping, 'dcmgr/models/tag_mapping'
    autoload :AccountResource, 'dcmgr/models/account_resource'
    autoload :Instance, 'dcmgr/models/instance'
    autoload :Image, 'dcmgr/models/image'
    autoload :HostNode, 'dcmgr/models/host_node'
    autoload :RequestLog, 'dcmgr/models/request_log'
    autoload :FrontendSystem, 'dcmgr/models/frontend_system'
    autoload :StorageNode, 'dcmgr/models/storage_node'
    autoload :Volume, 'dcmgr/models/volume'
    autoload :VolumeSnapshot, 'dcmgr/models/volume_snapshot'
    autoload :NetfilterGroup, 'dcmgr/models/netfilter_group'
    autoload :NetfilterRule, 'dcmgr/models/netfilter_rule'
    autoload :InstanceSpec, 'dcmgr/models/instance_spec'
    autoload :InstanceNic, 'dcmgr/models/instance_nic'
    autoload :Network, 'dcmgr/models/network'
    autoload :IpLease, 'dcmgr/models/ip_lease'
    autoload :InstanceNetfilterGroup, 'dcmgr/models/instance_netfilter_group'
    autoload :SshKeyPair, 'dcmgr/models/ssh_key_pair'
    autoload :History, 'dcmgr/models/history'
    autoload :HostnameLease, 'dcmgr/models/hostname_lease'
    autoload :MacLease, 'dcmgr/models/mac_lease'
    autoload :VlanLease, 'dcmgr/models/vlan_lease'
    autoload :Quota, 'dcmgr/models/quota'
  end

  module Endpoints
    autoload :CoreAPI, 'dcmgr/endpoints/core_api'
    autoload :Metadata, 'dcmgr/endpoints/metadata'
  end

  module NodeModules
    autoload :StaCollector, 'dcmgr/node_modules/sta_collector'
    autoload :StaTgtInitializer, 'dcmgr/node_modules/sta_tgt_initializer'
    autoload :HvaCollector, 'dcmgr/node_modules/hva_collector'
    autoload :InstanceHA, 'dcmgr/node_modules/instance_ha'
    autoload :ServiceNetfilter, 'dcmgr/node_modules/service_netfilter'
    autoload :ServiceOpenFlow, 'dcmgr/node_modules/service_openflow'
    autoload :InstanceMonitor, 'dcmgr/node_modules/instance_monitor'
    autoload :Scheduler, 'dcmgr/node_modules/scheduler'
    autoload :CustomEventHandler, 'dcmgr/node_modules/service_openflow'
    autoload :OpenFlowController, 'dcmgr/node_modules/service_openflow'
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
    autoload :Group, 'dcmgr/cli/group'
    autoload :Spec, 'dcmgr/cli/spec'
    autoload :Tag, 'dcmgr/cli/tag'
    autoload :Quota, 'dcmgr/cli/quota'
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
    autoload :BackingStore, 'dcmgr/drivers/backing_store'
    autoload :Zfs,          'dcmgr/drivers/zfs'
    autoload :Raw,          'dcmgr/drivers/raw'
    autoload :IscsiTarget,  'dcmgr/drivers/iscsi_target'
    autoload :SunIscsi,     'dcmgr/drivers/sun_iscsi'
    autoload :LinuxIscsi,   'dcmgr/drivers/linux_iscsi'
    autoload :Comstar,      'dcmgr/drivers/comstar'
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
    end
    module Network
      autoload :FlatSingle, 'dcmgr/scheduler/network/flat_single'
    end
  end
end
