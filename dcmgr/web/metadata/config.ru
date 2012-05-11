# -*- coding: utf-8 -*-

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'dcmgr/rubygems'
require 'dcmgr'

Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                ['/etc/wakame-vdc/dcmgr.conf',
                 File.expand_path('config/dcmgr.conf', Dcmgr::DCMGR_ROOT)
                ])

use Dcmgr::Rack::RunInitializer, lambda {
  Dcmgr.run_initializers
}, lambda {
  next if Isono::NodeModules::DataStore.disconnected? == false
  Dcmgr.run_initializers('sequel')
}

run Dcmgr::Endpoints::Ec2Metadata.new
