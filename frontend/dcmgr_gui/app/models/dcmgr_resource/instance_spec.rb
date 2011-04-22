module DcmgrResource
  class InstanceSpec < Base
    def self.list(params = {})
      self.find(:all,:params => params)
    end
  end
end
