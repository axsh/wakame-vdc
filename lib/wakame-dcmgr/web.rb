require 'rubygems'
require 'sinatra'
require 'sequel'

require 'wakame-dcmgr/models'
require 'wakame-dcmgr/public_crud'
require 'wakame-dcmgr/public_models'
require 'wakame-dcmgr/helpers'

module Wakame
  module Dcmgr
    class Web < Sinatra::Base
      helpers { include Wakame::Dcmgr::Helpers }
      
      public_crud PublicInstance
      public_crud PublicHvController
      
      #public_crud ImageStorage
      #public_crud HvSpec
      #public_crud PhysicalHost
      
      public_crud PublicGroup
      public_crud PublicUser
      
      get '/' do
        'startup wakame dcmgr'
      end
      
      not_found do
        if request.body.size > 0
          req_hash = JSON.parse(request.body.read)
          puts "request:" + req_hash.to_s
          "request:" + req_hash.to_s
        else
          puts "hoge"
          nil
        end
      end
    end
  end
end
