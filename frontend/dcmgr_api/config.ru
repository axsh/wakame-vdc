# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'autoload'
require 'rubygems'
require 'rack/request'

# Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
#                 ['/etc/wakame-vdc/dcmgr.conf',
#                  File.expand_path('config/dcmgr.conf', Dcmgr::DCMGR_ROOT)
#                 ])
# Dcmgr.run_initializers

map '/api' do
#   use Dcmgr::Rack::RequestLogger

  map '/12.03' do
    run Dcmgr::Endpoints::V1203::CoreAPI.new
  end
end
