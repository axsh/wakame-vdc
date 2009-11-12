require 'rubygems'
require 'sinatra'
require 'sequel'
require 'models'
require 'public_crud'
require 'json'

configure do
end

error do
end

helpers do
end

public_crud Instances

get '/' do
  'startup wakame dcmgr'
end
