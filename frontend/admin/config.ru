#!/usr/bin/env rackup
# encoding: utf-8

# This file can be used to start Padrino,
# just execute it from the command line.

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

require 'rack/cors'
use Rack::Cors do
  allow do
    origins '*'
    resource '/api/notifications', :headers => :any, :methods => [:get]
  end
end

require File.expand_path("../config/boot.rb", __FILE__)

run Padrino.application
