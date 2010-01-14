# -*- coding: utf-8 -*-
require 'rubygems'
require 'active_resource'

load('dcmgr-gui.conf')

class WebAPI < ActiveResource::Base
  self.site     = API_SERVER_URL
  self.format   = :json
  def self.login(user, pass)
    self.user = user
    self.password = pass
  end
end

class Account < WebAPI
end

class User < WebAPI
end

class AuthTag < WebAPI
end

class NameTag < WebAPI
end

class Instance < WebAPI
end

class HvController < WebAPI
end

class ImageStorage < WebAPI
end

class ImageStorageHost < WebAPI
end

class PhysicalHost < WebAPI
end
