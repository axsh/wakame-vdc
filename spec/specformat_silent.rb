$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'rubygems'
require "#{File.dirname(__FILE__)}/../vendor/gems/environment"
require 'logger'
require 'dcmgr'

logger = Logger.new(STDOUT)
logger.level = Logger::FATAL
Dcmgr.logger = logger

SPECFORMAT = true
