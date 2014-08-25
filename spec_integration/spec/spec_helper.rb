# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:test)

$LOAD_PATH << File.expand_path("./helpers", File.dirname(__FILE__))
require 'mussel'

RSpec::Core::ExampleGroup.define_example_group_method :feature
RSpec::Core::ExampleGroup.define_example_method :scenario

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true
end
