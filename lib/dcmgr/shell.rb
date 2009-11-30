
$:.unshift 'lib'
require 'dcmgr'
Dcmgr::Schema.connect \
  'mysql://localhost/wakame_dcmgr?user=wakame_dcmgr&password=passwd'
Dcmgr::Schema.create!

require 'dcmgr/web'
