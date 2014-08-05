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
  if Dcmgr::Configurations.dcmgr.dcmgr_dcell_node_uri
    require 'dcell'
    DCell.start(:id => Dcmgr::Configurations.dcmgr.dcmgr_dcell_node_id,
      :addr => "tcp://#{Dcmgr::Configurations.dcmgr.dcmgr_dcell_node_uri}",
      :registry => {
        :adapter => Dcmgr::Configurations.dcmgr.dcell_adapter,
        :host => Dcmgr::Configurations.dcmgr.dcell_host,
        :port => Dcmgr::Configurations.dcmgr.dcell_port
      }
    )
    Dcmgr.run_initializers('vnet_hook')
  end

  map '/12.03' do
    run Dcmgr::Endpoints::V1203::CoreAPI.new
  end
end
