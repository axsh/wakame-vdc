# -*- coding: utf-8 -*-
module DcmgrResource::V1203
  class InstanceSpec < Base
    
    self.prefix = '/api/11.12/'

    def self.list(params = {})
      self.find(:all,:params => params)
    end

    def self.show(uuid)
      self.get(uuid)
    end
  end
end
