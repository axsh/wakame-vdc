# -*- coding: utf-8 -*-

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'dcmgr/rubygems'
require 'dcmgr'

Dcmgr.configure(File.expand_path('../../../config/dcmgr.conf', __FILE__))

Dcmgr.run_initializers

map '/api/12.03' do
  run Dcmgr::Endpoints::CoreAPI_1203.new
end

run Dcmgr::Endpoints::CoreAPI.new
