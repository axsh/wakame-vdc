module Frontend::Models
  module DcmgrResource
    class Volume < Base
      def self.list(params = {})
        #todo:storage_pool_id is not implemented because of the fixed value
        params[:storage_pool_id] = 'sp-1sx9jeks'
        data = self.find(:all,:params => params)
        results = []
        data.each{|row|
          results << row.attributes
        }
        results
      end
    
      def self.create(params)
        volume = self.new
        volume.volume_size = params[:volume_size]
        volume.save
        volume
      end
  
      def self.destroy(volume_id)
        self.delete(volume_id).body
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

      def self.show(volume_id)
        self.get(volume_id)
      end
    end
  end
end