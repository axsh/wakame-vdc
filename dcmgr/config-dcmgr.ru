# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'dcmgr/rubygems'
require 'dcmgr'
require 'rack/cors'

Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                ['/etc/wakame-vdc/dcmgr.conf',
                 File.expand_path('config/dcmgr.conf', Dcmgr::DCMGR_ROOT)
                ])
Dcmgr.run_initializers('logger', 'sequel', 'isono', 'job_queue.sequel', 'sequel_class_method_hook')

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

map '/api' do
  use Dcmgr::Rack::RequestLogger
  use Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
    end
  end

  #TODO refactor
  if Dcmgr.conf.dcmgr_dcell_node_uri
    require 'dcell'
    DCell.start :id => Dcmgr.conf.dcmgr_dcell_node_id, :addr => "tcp://#{Dcmgr.conf.dcmgr_dcell_node_uri}"
    Dcmgr.run_initializers('vnet_hook')
  end

  map '/12.03' do
    run Dcmgr::Endpoints::V1203::CoreAPI.new
  end
  map '/11.12' do
    run Dcmgr::Endpoints::V1112::CoreAPI.new
  end

  run Dcmgr::Endpoints::V1112::CoreAPI.new
end
