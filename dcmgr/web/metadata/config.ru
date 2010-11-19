# -*- coding: utf-8 -*-

begin
  require 'rubygems'
  require 'bundler'
  Bundler.setup(:default, :dcmgr)
rescue ::Exception => e
end
$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'dcmgr'

if File.exists?('../../config/dcmgr.conf')
  Dcmgr.configure('../../config/dcmgr.conf')
else
  raise "Could not find the config/dcmgr.conf configuration file."
end
Dcmgr.run_initializers

run Dcmgr::Endpoints::Metadata.new
