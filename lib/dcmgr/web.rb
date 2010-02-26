require 'rubygems'
require 'sinatra'
require 'sequel'

require 'dcmgr/models'
require 'dcmgr/rest_models'
require 'dcmgr/helpers'

module Dcmgr
  class Web < Sinatra::Base
    set :logger, false
    helpers { include Dcmgr::Helpers }
    
    def self.public_crud model
      model.actions {|action, pattern, proc|
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
    helpers { include Dcmgr::AuthorizeHelpers }
    
    public_crud FrontendServiceUser
    
    public_crud PublicAccount
    public_crud PublicUser
    public_crud PublicKeyPair

    public_crud PublicNameTag
    public_crud PublicAuthTag
    public_crud PublicTagAttribute
    
    public_crud PublicInstance
    public_crud PublicPhysicalHost
    
    public_crud PublicImageStorage
    public_crud PublicImageStorageHost
    
    public_crud PublicLocationGroup

    get '/' do
      'startup dcmgr'
    end
  end
  
  class PrivateWeb < Web
    helpers { include Dcmgr::NoAuthorizeHelpers }
    public_crud PrivateInstance
    
    get '/' do
      'startup dcmgr. private mode'
    end
  end
end
