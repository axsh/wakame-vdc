
require 'sinatra'

set :run, false

require 'wakame-dcmgr/schema'

module Wakame
  module Dcmgr
    extend self

    def configure(config_file=nil)
      load(config_file) if config_file
      self
    end
    
    def options
      Sinatra.application.options
    end

    def new(config_file)
      config_file ||= 'dcmgr.conf'
      configure(config_file)
      require 'wakame-dcmgr/web'
      Web
    end
  end
end
