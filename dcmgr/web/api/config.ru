# -*- coding: utf-8 -*-

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'dcmgr/rubygems'
require 'dcmgr'

Dcmgr.configure(File.expand_path('../../../config/dcmgr.conf', __FILE__))

Dcmgr.run_initializers

map '/api/12.03' do
  run Dcmgr::Endpoints::V1203::CoreAPI.new
end
map '/api/11.12' do
  run Dcmgr::Endpoints::V1112::CoreAPI.new
end

run Dcmgr::Endpoints::V1112::CoreAPI.new
