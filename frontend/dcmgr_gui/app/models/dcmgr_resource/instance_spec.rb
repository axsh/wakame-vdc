module DcmgrResource
  class InstanceSpec < Base
    def self.list(params = {})
      self.find(:all,:params => params)
    end

    def self.show(uuid)
      self.get(uuid)
    end
  end
end
