# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class VolumeSnapshot < Base
    include DcmgrResource::ListMethods

    def self.list(params = {})
      data = self.find(:all, :params => params)
      results = []
      data.each { |row|
        results << row.attributes
      }
    end

    def self.create(params)
      snapshot = self.new
      snapshot.volume_id = params[:volume_id]
      snapshot.destination = params[:destination]
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
    
    def self.upload_destination
      result = self.get(:upload_destination)
      result
    end
  end
end
