module Frontend
  module Models
    module DcmgrResource
      class Base < ActiveResource::Base
        #todo:config
        self.site = "http://api.dcmgr.ubuntu.local/"
        self.timeout = 30
        self.format = :json
        self.prefix = '/api/'
      end
    end
  end
end