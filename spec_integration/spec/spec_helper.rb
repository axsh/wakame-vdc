# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:test)

RSpec.configure do |c|
  c.formatter = :documentation
  c.color     = true
end
