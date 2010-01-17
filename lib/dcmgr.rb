require 'logger'
require 'sinatra'

set :run, false

require 'dcmgr/schema'
require 'dcmgr/hvchttpmock'
require 'dcmgr/scheduler'

module Dcmgr
  extend self
  
  def configure(config_file=nil)
    load(config_file) if config_file
    self
  end
  
  def options
    Sinatra.application.options
  end

  def set_logger(logger)
    @logger = logger
    def @logger.write(str)
      self << str
    end
  end

  def logger
    set_logger Logger.new(STDOUT) unless @logger 
    @logger
  end

  def hvchttp
    @hvchttp ||= HvcHttpMock.new(HvController[1])
  end

  attr_writer :hvchttp

  def scheduler
    @scheduler ||= PhysicalHostScheduler::Algorithm2
  end

  attr_writer :scheduler
  
  def new(config_file)
    config_file ||= 'dcmgr.conf'
    configure(config_file)
    require 'dcmgr/web'
    Web
  end
end
