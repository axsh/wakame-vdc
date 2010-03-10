
$:.unshift 'lib'
require "#{File.dirname(__FILE__)}/../../vendor/gems/environment"
require "irb"

conf = ARGV.shift
if conf == "-client"
  require 'client/client'
else
  require 'dcmgr'
  include Dcmgr::Models
  Dcmgr.configure conf
end

IRB.start(__FILE__)
