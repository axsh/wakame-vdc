# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

version = ">= 0"

if ARGV.first =~ /^_(.*)_$/ and Gem::Version.correct? $1 then
  version = $1
  ARGV.shift
end

begin
  gem 'isono', version
rescue Gem::LoadError => e
end
require 'isono'
require 'dcmgr'
