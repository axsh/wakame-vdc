# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:test)

Dir["#{File.dirname(__FILE__)}/helpers/*.rb"].each {|f| require f }

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true
end
