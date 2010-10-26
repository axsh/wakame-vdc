module Frontend::Models
  module DcmgrResource
    class Volume < Base
      def self.list(params = {})
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
  
      def self.destroy(account_id,volume_id)
        self.delete(account_id,{:volume_id => volume_id}).body
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