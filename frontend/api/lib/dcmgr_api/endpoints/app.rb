require 'rubygems'
require 'sinatra/base'
require 'sinatra/rabbit'
require 'sinatra/authz_helper'

require 'json'

module Frontend
  module DcmgrApi
    module Endpoints
      class App < Sinatra::Base
        register Sinatra::Rabbit #Object.extend
        helpers Sinatra::AuthzHelper

        #http://yourserver/api/instances/1
        # use Rack::Auth::Basic do |username, password|
        #   [username, password] == ['admin', 'admin']
        # end

        collection :instances do
          operation :index do
            control do
              user_id = 1
              account_id = 1
              
              if authorized?(user_id,account_id,:AdminInstance)
                result = 'authorized success'
              else
                result = 'authorized fail'
              end
              respond_to{|f|
                f.html {result}
              }
            end
          end
        end
      end
    end
  end
end