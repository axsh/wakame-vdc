module DcmgrResource
  class HostPool < Base
    def self.list(params = {})
      self.find(:all,:params => params)
    end
    
    def self.show(host_pool_id)
      self.get(host_pool_id)
    end
  end
end
