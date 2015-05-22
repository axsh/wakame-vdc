# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

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
    resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
  end
end


run DcmgrGui::Application
