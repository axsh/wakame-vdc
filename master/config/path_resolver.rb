# -*- coding: utf-8 -*-

begin
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError => e
  require 'rubygems'
  #require 'bundler'
  #Bundler.setup
end
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

version = ">= 0"

if ARGV.first =~ /^_(.*)_$/ and Gem::Version.correct? $1 then
  version = $1
  ARGV.shift
end

begin
  gem 'isono', version
rescue Gem::LoadError => e
  $LOAD_PATH.unshift File.expand_path('../../../isono/lib', __FILE__)
  require 'isono'
end
