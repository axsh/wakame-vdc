begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup(:root=>File.expand_path('../../../', __FILE__))
end
$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'sinatra'
require 'logger'
require 'dcmgr'

run Dcmgr.new('dcmgr.conf', :public)
