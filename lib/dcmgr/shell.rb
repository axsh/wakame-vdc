
$:.unshift 'lib'
require 'dcmgr'
Dcmgr::Schema.connect 'mysql://localhost/wakame_dcmgr_test?user=dcmgr_test&password=passwd'
require 'dcmgr/web'
