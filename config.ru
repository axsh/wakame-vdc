require 'rubygems'
# Load local envrironment file which bundler generates.
require "#{File.dirname(__FILE__)}/vendor/gems/environment"

require 'dcmgr-gui'
run Sinatra::Application
