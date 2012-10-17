# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

require 'rack/cors'
use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
  end
end


run DcmgrGui::Application
