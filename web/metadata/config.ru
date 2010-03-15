begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../../.bundle/environemnt', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end
$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'sinatra'
require 'dcmgr'

run Dcmgr::Web::Metadata.new
