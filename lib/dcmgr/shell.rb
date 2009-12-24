
$:.unshift 'lib'
require 'dcmgr'
Dcmgr::Schema.connect 'mysql://localhost/wakame_dcmgr?user=dcmgr&password=passwd'
require 'dcmgr/web'
