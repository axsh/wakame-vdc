module Frontend::Models
  module DcmgrResource
    class Volume < Base
      def self.show(account_id)
        self.get(account_id)
      end
    
      # def self.create
      # end
  
      def self.destroy(account_id,volume_id)
        self.delete(account_id).body
      end
    
      def self.attach(account_id,instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,account_id)
        result = self.put(:attach)
        self.collection_name = @collection
        result.body
      end
    
      def self.detach(account_id,instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,account_id)
        result = self.put(:detach)
        self.collection_name = @collection
        result.body
      end

      def self.status(account_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,account_id)
        result = self.get(:status)
        self.collection_name = @collection
        result
      end

      def self.detail(account_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,account_id)
        result = self.get(:detail)
        self.collection_name = @collection
        result
      end
    end
  end
end