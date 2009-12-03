$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'rubygems'
require 'sinatra'
require 'logger'
# Load local envrironment file which bundler generates.
require "#{File.dirname(__FILE__)}/vendor/gems/environment"
require 'dcmgr'

run Dcmgr.new('dcmgr.conf')

