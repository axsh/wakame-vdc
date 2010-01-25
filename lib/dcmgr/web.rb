require 'rubygems'
require 'sinatra'
require 'sequel'

require 'dcmgr/models'
require 'dcmgr/public_models'
require 'dcmgr/helpers'

module Dcmgr
  class Web < Sinatra::Base
    set :logger, false
    helpers { include Dcmgr::Helpers }
    
    def self.public_crud model
      model.get_actions {|action, pattern, proc|
        Dcmgr::logger.debug "REGIST: %s %s" % [action, pattern]
        self.send action, pattern, &proc
      }
    end

    not_found do
      logger.debug "not found: #{request.request_method} #{request.path}"
      "not found"
    end
  end
  
  class PublicWeb < Web
    public_crud PublicAccount
    public_crud PublicUser
    
    public_crud PublicNameTag
    public_crud PublicAuthTag
    
    public_crud PublicInstance
    public_crud PublicPhysicalHost
    
    public_crud PublicImageStorage
    public_crud PublicImageStorageHost
    
    get '/' do
      'startup dcmgro'
    end
  end
  
  class PrivateWeb < Web
    public_crud PublicInstance
    public_crud PublicPhysicalHost
    
    get '/' do
      'startup dcmgr. private mode'
    end
  end
end
