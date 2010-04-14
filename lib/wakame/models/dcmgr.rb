require 'rubygems'
require 'active_resource'

module Wakame
  module Models
    class Dcmgr < ActiveResource::Base
      self.site = Wakame.config.dcmgr_private_endpoint
      self.format = :json
    end

    class Instance < Dcmgr
    end
  end
end
