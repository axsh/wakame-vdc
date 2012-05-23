# -*- coding: utf-8 -*-
module DcmgrResource::V1203
  class Image < Base
    def self.list(params = {})
      self.find(:all,:params => params)
    end
    
    def self.show(image_id)
      self.get(image_id)
    end

  end
end
