# -*- coding: utf-8 -*-

require 'rubygems'
require 'active_resource'

URL = "http://dcmgr.opty.jp/"
#URL = "http://192.168.1.133:3000/"
#URL = "http://192.168.1.135/"

class WebAPI < ActiveResource::Base
  self.site     = URL
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

class Tag < WebAPI
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
