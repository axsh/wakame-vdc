# This file is used by Rack-based servers to start the application.
require 'sinatra'
require ::File.expand_path('../config/environment-api',  __FILE__)
run DcmgrGui::AuthServer
