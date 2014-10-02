#!/usr/bin/env rackup
# encoding: utf-8

# This file can be used to start Padrino,
# just execute it from the command line.

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC

  require 'unicorn/worker_killer'
  # Max requests per worker: 1000 reqs - 1200 reqs
  use Unicorn::WorkerKiller::MaxRequests, 1000, 1200
  # Max memory size (RSS) per worker: 300MB - 500MB
  use Unicorn::WorkerKiller::Oom, ((300) * (1024**2)), ((500) * (1024**2))
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
