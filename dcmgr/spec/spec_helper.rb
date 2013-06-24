# -*- coding: utf-8 -*-
require 'rubygems'
require 'dcmgr'

RSpec.configure do |config|
  Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                  [File.expand_path('../config/dcmgr.conf', __FILE__)])
  Dcmgr.run_initializers("sequel")
end
