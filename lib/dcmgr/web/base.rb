require 'sinatra'
require 'sequel'

module Dcmgr::Web
  class Base < Sinatra::Base
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
end
