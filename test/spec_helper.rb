
root = File.expand_path("#{File.dirname(__FILE__)}/..")
$:.unshift "#{root}/lib"
$:.unshift "#{root}/test"

require 'rubygems'
require 'wakame-dcmgr'

Wakame::Dcmgr.connection_configure = 'sqlite:/'

require 'wakame-dcmgr/schema'
require 'wakame-dcmgr/models'
