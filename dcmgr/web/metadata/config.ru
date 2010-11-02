# -*- coding: utf-8 -*-

require "rubygems"
require "bundler/setup"

$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'dcmgr'

if File.exists?('./dcmgr.conf')
  Dcmgr.configure('./dcmgr.conf')
elsif File.exists?('../../dcmgr.conf')
  Dcmgr.configure('../../dcmgr.conf')
else
  raise "Could not find the configuration file."
end
Dcmgr.run_initializers

run Dcmgr::Endpoints::Metadata.new
