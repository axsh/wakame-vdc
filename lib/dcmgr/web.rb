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
      model.public_actions.each{|method_name, pattern, actiontag, args|
        Dcmgr.logger.debug "#{method_name} #{pattern}, &model.get_action(model, actiontag, args)"
        eval("#{method_name} pattern, &model.get_action(model, actiontag, args)")
      }
    end

    public_crud PublicInstance
    public_crud PublicHvController
    public_crud PublicImageStorage
    public_crud PublicImageStorageHost
    public_crud PublicPhysicalHost
    
    public_crud PublicUser
    
    get '/' do
      'startup dcmgr'
    end
    
    not_found do
      logger.debug "not found"
      if request.body.size > 0
        req_hash = JSON.parse(request.body.read)
        
        "not found " + req_hash.to_s
      else
        "no request data"
      end
    end
  end
end
