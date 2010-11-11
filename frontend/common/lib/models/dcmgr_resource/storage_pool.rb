module Frontend::Models
  module DcmgrResource
    class StoragePool < Base
      def self.list(params = {})
        self.find(:all,:params => params)
      end
      
      def self.show(storage_pool_id)
        self.get(storage_pool_id)
      end
    end
  end
end