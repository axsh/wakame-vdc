
require 'sinatra'
set :run, false

module Wakame
  module Dcmgr
    extend self

    def configure(config_file=nil)
      load(config_file) if config_file
      require 'wakame-dcmgr/models'
      self
    end
    
    def options
      Sinatra.application.options
    end

    def connection_configure=(str)
      @connection = str
    end

    def connection_configure
      @connection
    end
    
    def new(config_file)
      config_file ||= 'dcmgr.conf'
      configure(config_file)
      require 'wakame-dcmgr/web'
      Sinatra.application
    end
  end
end
   
    
