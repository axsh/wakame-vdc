$:.unshift "#{File.dirname(__FILE__)}/../lib"
require 'logger'
require 'dcmgr'

logger = Logger.new(STDOUT)
logger.level = Logger::FATAL
Dcmgr.logger = logger

SPECFORMAT = true
