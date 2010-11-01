require 'logger'
require 'configuration'

module Dcmgr
  extend self

  class << self
    def conf
      @conf
    end

    def configure(config_path=nil, &blk)
      return self if @conf
      
      if config_path.is_a?(String)
        raise "Could not find configration file: #{config_path}" unless File.exists?(config_path)

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
    initializers_root = File.expand_path('conf/initializers', DCMGR_ROOT) 
    
    if File.directory?(initializers_root)
      Dir.glob("#{initializers_root}/*.rb") { |f|
        ::Kernel.load(f)
      }
    end
  }
  
  
  def logger=(logger)
    @logger = logger
    def @logger.write(str)
      self << str
    end
  end

  def logger
    self.logger = Logger.new(STDOUT) unless @logger 
    @logger
  end

  attr_accessor :location_groups

  def fsuser_auth_type=(type)
    FsuserAuthorizer.auth_type = type
  end

  def fsuser_auth_type
    FsuserAuthorizer.auth_type
  end

  def fsuser_auth_users=(users)
    FsuserAuthorizer.auth_users = users
  end

  def fsuser_auth_users
    FsuserAuthorizer.auth_users
  end
  
  def hvchttp
    #@hvchttp ||= HvcHttpMock.new
    @hvchttp ||= HvcHttp.new
  end

  attr_writer :hvchttp

  def scheduler
    @scheduler ||= PhysicalHostScheduler::Algorithm2.new
  end
  
  def scheduler=(scheduler_module)
    @scheduler = scheduler_module.new
  end

  def db
    Dcmgr::Schema.db
  end
  
  def new(config_file, mode=:public)
    config_file ||= 'dcmgr.conf'
    configure(config_file)
    case mode
    when :public
      Web::Public
    when :private
      Web::Private
    else
      raise Exception, "unkowon mode: #{mode}"
    end
  end

  autoload :Schema, 'dcmgr/schema'
  autoload :FsuserAuthorizer, 'dcmgr/fsuser_authorizer'
  autoload :KeyPairFactory, 'dcmgr/keypair_factory'
  autoload :PhysicalHostScheduler, 'dcmgr/scheduler'
  autoload :IPManager, 'dcmgr/ipmanager'
  autoload :HvcHttp, 'dcmgr/hvchttp'
  autoload :HvcAccess, 'dcmgr/hvchttp'
  autoload :HvcHttpMock, 'dcmgr/hvchttp/mock'

  autoload :RoleExecutor, 'dcmgr/evaluator'
  autoload :Helpers, 'dcmgr/helpers'

  module Models
    autoload :Base, 'dcmgr/models/base'
    autoload :KeyPair, 'dcmgr/models/key_pair'
    autoload :TagAttribute, 'dcmgr/models/tag_attribute'
    autoload :IpGroup, 'dcmgr/models/ip_group'
    autoload :Ip, 'dcmgr/models/ip'
    autoload :HvController, 'dcmgr/models/hv_controller'
    autoload :HvAgent, 'dcmgr/models/hv_agent'
    autoload :ImageStorage, 'dcmgr/models/image_storage'
    autoload :ImageStorageHost, 'dcmgr/models/image_storage_host'
    autoload :PhysicalHost, 'dcmgr/models/physical_host'
    autoload :LocationGroup, 'dcmgr/models/location_group'
    autoload :Log, 'dcmgr/models/log'
    autoload :AccountLog, 'dcmgr/models/account_log'

    CREATE_TABLE_CLASSES=[:Account,:Tag,:TagMapping,:FrontendSystem,
                          :Image,:HostPool,:RequestLog,:Instance,
                          :NetfilterGroup, :NetfilterRule,
                          :StorageAgent,:StoragePool,:Volume,:VolumeSnapshot,
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
    autoload :StorageAgent, 'dcmgr/models/storage_agent'
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
  end

  module RestModels
    autoload :Base, 'dcmgr/rest_models/base'
    autoload :Public, 'dcmgr/rest_models/public'
    autoload :Private, 'dcmgr/rest_models/private'
  end

  module Web
    autoload :Base, 'dcmgr/web/base'
    autoload :Public, 'dcmgr/web/public'
    autoload :Private, 'dcmgr/web/private'
    autoload :Metadata, 'dcmgr/web/metadata'
  end

  module Endpoints
    autoload :CoreAPI, 'dcmgr/endpoints/core_api'
  end

  module NodeModules
    autoload :StaCollector, 'dcmgr/node_modules/sta_collector'
    autoload :HvaCollector, 'dcmgr/node_modules/hva_collector'
  end

  autoload :CertificatedActiveResource, 'dcmgr/certificated_active_resource'
end
