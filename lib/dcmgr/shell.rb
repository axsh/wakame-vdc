
$:.unshift 'lib'
require "#{File.dirname(__FILE__)}/../../vendor/gems/environment"
require 'dcmgr'
include Dcmgr::Models

Dcmgr.configure ARGV.shift

require "irb"
IRB.start(__FILE__)
