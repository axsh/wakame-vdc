require 'logger'
require 'sinatra'

set :run, false

require 'dcmgr/schema'
require 'dcmgr/hvchttp'
require 'dcmgr/hvchttp/mock'
require 'dcmgr/scheduler'

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

  def hvchttp
    @hvchttp ||= HvcHttpMock.new(HvController[1])
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
    require 'dcmgr/web'
    case mode
    when :public
      PublicWeb
    when :private
      PrivateWeb
    else
      raise Exception, "unkowon mode: #{mode}"
    end
  end
end
