$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'rubygems'
# Load local envrironment file which bundler generates.
require File.expand_path('../../../vendor/gems/environment', __FILE__)
require 'sinatra'
require 'dcmgr'

run Dcmgr::Web::Metadata.new
