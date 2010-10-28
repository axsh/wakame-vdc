module Frontend::Models
  module DcmgrResource
    class Instance < Base
      def self.list(params = {})
        self.find(:all,:params => params)
      end
      
      def self.show(instance_id)
        self.get(instance_id)
      end
      
      def self.create(params)
        instance = self.new
        instance.image_id = params[:image_id]
        instance.host_pool_id = params[:host_pool_id]
        instance.save
        instance
      end
      
      def self.destroy(instance_id)
        self.delete(instance_id).body
      end
      
    end
  end
end