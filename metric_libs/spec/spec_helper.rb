# -*- coding: utf-8 -*-

require 'rubygems'

# Setup Bundler
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(File.dirname(__FILE__) + '/Gemfile')
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
Bundler.require :default if defined?(Bundler)
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'metric_libs'

RSpec.configure do |c|
end
