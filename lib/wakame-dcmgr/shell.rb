
$:.unshift 'lib'
require 'wakame-dcmgr'
Wakame::Dcmgr::Schema.connect \
  'mysql://localhost/wakame_dcmgr?user=wakame_dcmgr&password=passwd'
Wakame::Dcmgr::Schema.create!

