require 'logger'
require 'sinatra'

set :run, false

require 'dcmgr/schema'
require 'dcmgr/hvchttpmock'

module Dcmgr
  extend self
  @@logger = Logger.new(STDOUT)

  def configure(config_file=nil)
    load(config_file) if config_file
    self
  end
  
  def options
    Sinatra.application.options
  end

  def set_logger(logger)
    @@logger = logger
  end

  def logger
    @@logger
  end

  def hvchttp
    @@hvchttp ||= HvcHttpMock
    @@hvchttp
  end

  def set_hvcsrv(hvchttp)
    @@hvchttp = hvhttp
  end
  
  def new(config_file)
    config_file ||= 'dcmgr.conf'
    configure(config_file)
    require 'dcmgr/web'

    Web
  end
end
