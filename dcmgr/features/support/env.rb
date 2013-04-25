# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)

require 'dcmgr/rubygems'
require 'dcmgr'
require 'fuguta'


Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                [File.expand_path('../dcmgr.conf', __FILE__)])

Dcmgr.run_initializers()

DEFAULT_ACCOUNT="a-shpoolxx"
