module Frontend::Models
  module DcmgrResource
    class VolumeSnapshot < Base
      def self.show(account_id)
        self.get(account_id)
      end
    
      # def self.create
      # end
    
      def self.destroy(account_id,snapshot_id)
        self.delete(snapshot_id).body
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