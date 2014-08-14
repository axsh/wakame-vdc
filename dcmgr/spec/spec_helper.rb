# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:test)

require 'dcmgr'

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true

  c.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with :truncation
  end

  c.before(:each) do
    DatabaseCleaner.start
    Fabrication.clear_definitions
  end

  c.after(:each) do
    DatabaseCleaner.clean
  end
end

Dcmgr::Configurations.load Dcmgr::Configurations::Dcmgr,
  [File.expand_path('../minimal_dcmgr.conf', __FILE__)]

Dcmgr::Configurations.load Dcmgr::Configurations::Hva,
  [File.expand_path('../minimal_hva.conf', __FILE__)]

Dcmgr.run_initializers('sequel')
