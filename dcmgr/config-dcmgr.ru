# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'dcmgr/rubygems'
require 'dcmgr'

Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                ['/etc/wakame-vdc/dcmgr.conf',
                 File.expand_path('config/dcmgr.conf', Dcmgr::DCMGR_ROOT)
                ])
Dcmgr.run_initializers

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

map '/api' do
  use Dcmgr::Rack::RequestLogger

  map '/12.03' do
    run Dcmgr::Endpoints::V1203::CoreAPI.new
  end
  map '/11.12' do
    run Dcmgr::Endpoints::V1112::CoreAPI.new
  end

  run Dcmgr::Endpoints::V1112::CoreAPI.new
end
