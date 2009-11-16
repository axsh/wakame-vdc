require 'rubygems'
require 'sinatra'
require 'sequel'
require 'json'

require 'wakame-dcmgr/models'
require 'wakame-dcmgr/public_crud'
require 'wakame-dcmgr/helpers'

helpers { include Wakame::Dcmgr::Helpers }

public_crud Instance
public_crud ImageStorage
public_crud HvSpec
public_crud PhysicalHost

public_crud Group
public_crud User

get '/' do
  'startup wakame dcmgr'
end
