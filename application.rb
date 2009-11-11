require 'rubygems'
require 'sinatra'
require 'sequel'
require 'models'

configure do
end

error do
end

helpers do
end

get '/' do
  'startup wakame dcmgr'
end
