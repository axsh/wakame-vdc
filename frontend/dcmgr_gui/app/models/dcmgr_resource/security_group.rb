module DcmgrResource
  class SecurityGroup < Base

    def self.create(params)
      security_group = self.new
      security_group.description = params[:description]
      security_group.rule = params[:rule]
      security_group.save
      security_group
    end

    def self.list(params = {})
     self.find(:all,:params => params)
    end

    def self.show(uuid)
      self.get(uuid)
    end
              
    def self.update(uuid,params)
      self.put(uuid,params).body
    end
    
    def self.destroy(uuid)
      self.delete(uuid).body
    end      
  end
end
