# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)

require 'dcmgr/rubygems'
require 'dcmgr'


Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                ['/etc/wakame-vdc/dcmgr.conf',
                 File.expand_path('config/dcmgr.conf', Dcmgr::DCMGR_ROOT)
                ])

Dcmgr.run_initializers()

DEFAULT_ACCOUNT="a-shpoolxx"
