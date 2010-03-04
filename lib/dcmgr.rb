require 'logger'
require 'sinatra'

set :run, false

require 'dcmgr/route'

module Dcmgr
  extend self

  def configure(config_file=nil)
    load(config_file) if config_file
    self
  end
  
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
    @hvchttp ||= HvcHttpMock.new
  end

  attr_writer :hvchttp

  def scheduler
    @scheduler ||= PhysicalHostScheduler::Algorithm2.new
  end
  
  def scheduler=(scheduler_module)
    @scheduler = scheduler_module.new
  end

  def assign_ips=(ips)
    IPManager.setup ips
  end

  def db
    Dcmgr::Schema.db
  end
  
  def new(config_file, mode=:public)
    config_file ||= 'dcmgr.conf'
    configure(config_file)
    require 'dcmgr/web'
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
    autoload :Account, 'dcmgr/models/account'
    autoload :AccountsUser, 'dcmgr/models/accounts_user'
    autoload :User, 'dcmgr/models/user'
    autoload :KeyPair, 'dcmgr/models/key_pair'
    autoload :Tag, 'dcmgr/models/tag'
    autoload :TagAttribute, 'dcmgr/models/tag_attribute'
    autoload :TagMapping, 'dcmgr/models/tag_mapping'
    autoload :Instance, 'dcmgr/models/instance'
    autoload :HvController, 'dcmgr/models/hv_controller'
    autoload :HvAgent, 'dcmgr/models/hv_agent'
    autoload :ImageStorage, 'dcmgr/models/image_storage'
    autoload :ImageStorageHost, 'dcmgr/models/image_storage_host'
    autoload :PhysicalHost, 'dcmgr/models/physical_host'
    autoload :LocationGroup, 'dcmgr/models/location_group'
    autoload :Log, 'dcmgr/models/log'
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

end
