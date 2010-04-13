$:.unshift 'lib'
require "irb"

conf = ARGV.shift
if conf == "-client"
  require 'client/client'
else
  require 'dcmgr'
  Dcmgr.configure conf
  #Dcmgr::Models
  #include Dcmgr::Models
end

IRB.start(__FILE__)
