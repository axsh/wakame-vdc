# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'dcmgr/rubygems'
require 'dcmgr'

Dcmgr::Configurations.load Dcmgr::Configurations::Dcmgr

Dcmgr.run_initializers('logger', 'sequel')

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

run Dcmgr::Endpoints::Ec2Metadata.new
