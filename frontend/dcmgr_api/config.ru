# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'autoload'
require 'hijiki'
require 'rubygems'
require 'rack/request'

# Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
#                 ['/etc/wakame-vdc/dcmgr.conf',
#                  File.expand_path('config/dcmgr.conf', Dcmgr::DCMGR_ROOT)
#                 ])
# Dcmgr.run_initializers

# Hijiki::Request::Common::Defaults.request_defaults[:domain] = dcmgr_gui_config['dcmgr_site'].gsub(/\/$/, '')
Hijiki::Request::Common::Defaults.request_defaults[:domain] = 'http://localhost:9001/'.gsub(/\/$/, '')

map '/api' do
#   use Dcmgr::Rack::RequestLogger

  map '/12.03' do
    run Dcmgr::Endpoints::V1203::CoreAPI.new
  end
end
