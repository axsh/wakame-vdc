# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:test)

require 'dcmgr'

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true
end

Dcmgr.load_conf(
  Dcmgr::Configurations::Dcmgr,
  [File.expand_path('../minimal_dcmgr.conf', __FILE__)]
)

Dcmgr.run_initializers('sequel')
