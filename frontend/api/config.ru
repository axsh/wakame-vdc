#todo:bundler

$:.unshift "#{File.expand_path("./lib")}"
require 'dcmgr_api'

run Frontend::DcmgrApi.start('api.conf') #without api.conf