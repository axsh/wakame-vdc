# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

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

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

run Dcmgr::Endpoints::Ec2Metadata.new
