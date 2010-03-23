$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'rubygems'
begin
  require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
rescue
  require "#{File.dirname(__FILE__)}/../.bundle/environment"
end
require 'dcmgr'

SPECFORMAT = true

