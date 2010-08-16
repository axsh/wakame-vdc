# -*- coding: utf-8 -*-
begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
end
$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'dcmgr'
# Preload the endpoint to get initializer_hooks() installed.

if File.exists?('./dcmgr.conf')
  Dcmgr.configure('./dcmgr.conf')
elsif File.exists?('../../dcmgr.conf')
  Dcmgr.configure('../../dcmgr.conf')
else
  raise "Could not find the configuration file."
end
Dcmgr.run_initializers

run Dcmgr::Endpoints::CoreAPI.new
