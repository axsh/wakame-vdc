module Frontend::Models
  module DcmgrResource
    class Instance < Base
      def self.list(params = {})
        self.find(:all,:params => params)
      end
      
      def self.show(instance_id)
        self.get(instance_id)
      end
    end
  end
end