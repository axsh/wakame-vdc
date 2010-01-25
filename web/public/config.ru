$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'rubygems'
# Load local envrironment file which bundler generates.
require "#{File.dirname(__FILE__)}/../../vendor/gems/environment"
require 'sinatra'
require 'logger'
require 'dcmgr'

run Dcmgr.new('dcmgr.conf', :public)
