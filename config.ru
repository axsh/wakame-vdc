require 'rubygems'
require 'sinatra'

log = File.new("dcmgr.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

root = File.dirname(__FILE__)
$:.unshift "#{root}/lib"

require 'wakame-dcmgr'

run Wakame::Dcmgr.new('dcmgr.conf')

