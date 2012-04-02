# -*- coding: utf-8 -*-

setup_rb = File.expand_path('../../../vendor/bundle/bundler/setup.rb', __FILE__)
begin
  require 'rubygems'
  require 'bundler/setup'
  load setup_rb if File.exists?(setup_rb)
rescue LoadError => e
  load setup_rb if File.exists?(setup_rb)
end
