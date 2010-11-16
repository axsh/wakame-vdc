module DcmgrResource
  class VolumeSnapshot < Base

    def self.list(params = {})
      data = self.find(:all, :params => params)
      results = []
      data.each { |row|
        results << row.attributes
      }
    end

    def self.show(snapshot_id)
      self.get(snapshot_id)
    end
  
    def self.create(params)
      snapshot = self.new
      snapshot.volume_id = params[:volume_id]
      #todo:storage_pool_id is not implemented because of the fixed value
      snapshot.storage_pool_id = 'sp-1sx9jeks'
      snapshot.save
      snapshot
    end
  
    def self.destroy(snapshot_id)
      self.delete(snapshot_id).body
    end
    
    def self.status(account_id)
      @collection ||= self.collection_name
      self.collection_name = File.join(@collection,account_id)
      result = self.get(:status)
      self.collection_name = @collection
      result
    end
  end
end
