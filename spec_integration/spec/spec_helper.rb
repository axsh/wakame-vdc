# -*- coding: utf-8 -*-

require 'yaml'
require 'rubygems'
require 'bundler'
require 'net/ssh'
Bundler.setup(:default)
Bundler.require(:test)

$LOAD_PATH << File.expand_path("./helpers", File.dirname(__FILE__))
require 'mussel'

Dir.glob("#{File.dirname(__FILE__)}/helpers/helper_*.rb").each do |f|
  require f
end

RSpec::Core::ExampleGroup.define_example_group_method :feature
RSpec::Core::ExampleGroup.define_example_method :scenario

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true
end
