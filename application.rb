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
  def protected!
    response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth") and \
    throw(:halt, [401, "Not authorized\n"]) and \
    return unless authorized?
  end
  
  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? &&
      @auth.credentials && @auth.credentials == ['user', 'pass']
  end
end

public_crud Instances

get '/' do
  'startup wakame dcmgr'
end
