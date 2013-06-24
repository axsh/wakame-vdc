# -*- coding: utf-8 -*-
require 'rubygems'
require 'dcmgr'
require 'database_cleaner'
require 'isono' # Isono is needed for adding host nodes to the database

RSpec.configure do |config|
  Dcmgr.load_conf(Dcmgr::Configurations::Dcmgr,
                  [File.expand_path('../config/dcmgr.conf', __FILE__)])
  Dcmgr.run_initializers("logger","sequel")

  config.color_enabled = true
  config.formatter = :documentation

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
