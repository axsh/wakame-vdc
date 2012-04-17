# -*- coding: utf-8 -*-

setup_rb = File.expand_path('../../../vendor/bundle/bundler/setup.rb', __FILE__)

begin
  require 'rubygems'
  if File.exists?(setup_rb)
    load setup_rb
  else
    require 'bundler/setup'
  end
rescue LoadError => e
end
