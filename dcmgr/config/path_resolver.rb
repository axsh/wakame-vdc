# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if Object.const_defined?(:Gem)
  begin
    gem 'isono'
  rescue Gem::LoadError => e
  end
end
require 'isono'
require 'dcmgr'
