# -*- coding: utf-8 -*-

require 'rubygems'
require 'rspec'


# TODO: Factory Girl
# TODO: Rack Test
# TODO: JSON Test
RSpec.configure do |c|
  c.filter_run_excluding :smtp => true
end
