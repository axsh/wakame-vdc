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
    @auth.provided? && @auth.basic? && authorize(@auth.credentials, @auth.credentials)
  end

  def authorize(user, pass)
    
  end
end

public_crud Instance
public_crud ImageStorage
public_crud HvSpec
public_crud PhysicalHost

public_crud Group
public_crud User

get '/' do
  'startup wakame dcmgr'
end
