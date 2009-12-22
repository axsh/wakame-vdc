
$:.unshift 'lib'
require "#{File.dirname(__FILE__)}/../../vendor/gems/environment"
require 'dcmgr'
Dcmgr::Schema.connect 'mysql://localhost/wakame_dcmgr_test?user=dcmgr_test&password=passwd'
require 'dcmgr/web'
