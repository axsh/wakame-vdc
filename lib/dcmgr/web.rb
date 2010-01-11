require 'rubygems'
require 'sinatra'
require 'sequel'

require 'dcmgr/models'
require 'dcmgr/public_models'
require 'dcmgr/helpers'

module Dcmgr
  class Web < Sinatra::Base
    set :logger, false
    use Rack::CommonLogger, Dcmgr.logger
    helpers { include Dcmgr::Helpers }
    
    def self.public_crud model
      model.get_actions {|action, pattern, proc|
        Dcmgr::logger.debug "REGIST: %s %s" % [action, pattern]
        self.send action, pattern, &proc
      }
    end
    
    public_crud PublicAccount
    public_crud PublicUser
    
    public_crud PublicNameTag
    public_crud PublicAuthTag
    
    public_crud PublicInstance
    public_crud PublicPhysicalHost
    
    public_crud PublicImageStorage
    public_crud PublicImageStorageHost
    
    get '/' do
      'startup dcmgr'
    end
    
    not_found do
      logger.debug "not found"
      #if request.body.size > 0
      #  req_hash = JSON.parse(request.body.read)
        
      #  "not found " + req_hash.to_s
      #else
        "no request data"
      #end
    end
  end
end
