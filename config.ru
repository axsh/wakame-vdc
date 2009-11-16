require 'rubygems'
require 'sinatra'

Sinatra::Application.default_options.merge!(
	:run => false,
	:enf => :production
)

log = File.new("dcmgr.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

root = File.dirname(__FILE__)
$:.unshift "#{root}/lib"

require 'wakame-dcmgr'

run Sinatra::Application
