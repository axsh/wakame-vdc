require 'rubygems'
require 'sinatra'

log = File.new("dcmgr.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

root = File.dirname(__FILE__)
$:.unshift "#{root}/lib"

# Load local envrironment file which bundler generates.
require "#{root}/vendor/gems/environment"
require 'dcmgr'

run Dcmgr.new('dcmgr.conf')

