# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:test)

require 'dcmgr'

require_relative 'helper_methods'

DEFAULT_DATABASE_CLEANER_STRATEGY = :transaction

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true

  c.before(:suite) do
    # We truncate the database once before running the entire suite
    DatabaseCleaner.clean_with :truncation

    # We cleanup any data after tests using transactions since it's a lot faster
    DatabaseCleaner.strategy = DEFAULT_DATABASE_CLEANER_STRATEGY
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

Dcmgr.run_initializers('sequel', 'logger')
