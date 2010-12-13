# -*- coding: utf-8 -*-

module Dcmgr
  VERSION='10.11.0'

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

    def run_initializers()
      raise "Complete the configuration prior to run_initializers()." if @conf.nil?
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
      DCMGR_ROOT = ENV['DCMGR_ROOT'] || File.expand_path('../../', __FILE__)
    }
  }
  
  # Add conf/initializers/*.rb loader 
  initializer_hooks {
    initializers_root = File.expand_path('config/initializers', DCMGR_ROOT) 
    
    if File.directory?(initializers_root)
      Dir.glob("#{initializers_root}/*.rb") { |f|
        ::Kernel.load(f)
      }
    end
  }
  
  autoload :Logger, 'dcmgr/logger'
  
  module Models
    autoload :Base, 'dcmgr/models/base'

    CREATE_TABLE_CLASSES=[:Account,:Tag,:TagMapping,:FrontendSystem,
                          :Image,:HostPool,:RequestLog,:Instance,
                          :NetfilterGroup, :NetfilterRule,
                          :StoragePool,:Volume,:VolumeSnapshot,
                          :InstanceNetfilterGroup,
                          :InstanceSpec, :InstanceNic, :Network, :IpLease,
                          :SshKeyPair].freeze
    autoload :BaseNew, 'dcmgr/models/base_new'
    autoload :Account, 'dcmgr/models/account'
    autoload :Tag, 'dcmgr/models/tag'
    autoload :TagMapping, 'dcmgr/models/tag_mapping'
    autoload :AccountResource, 'dcmgr/models/account_resource'
    autoload :Instance, 'dcmgr/models/instance'
    autoload :Image, 'dcmgr/models/image'
    autoload :HostPool, 'dcmgr/models/host_pool'
    autoload :RequestLog, 'dcmgr/models/request_log'
    autoload :FrontendSystem, 'dcmgr/models/frontend_system'
    autoload :StoragePool, 'dcmgr/models/storage_pool'
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
  end

  module Endpoints
    autoload :CoreAPI, 'dcmgr/endpoints/core_api'
    autoload :Metadata, 'dcmgr/endpoints/metadata'
  end

  module NodeModules
    autoload :StaCollector, 'dcmgr/node_modules/sta_collector'
    autoload :HvaCollector, 'dcmgr/node_modules/hva_collector'
  end

  module Stm
    autoload :VolumeContext, 'dcmgr/stm/volume_context'
    autoload :SnapshotContext, 'dcmgr/stm/snapshot_context'
    autoload :Instance, 'dcmgr/stm/instance'
  end

  module Helpers
    autoload :CliHelper, 'dcmgr/helpers/cli_helper'
  end
end
