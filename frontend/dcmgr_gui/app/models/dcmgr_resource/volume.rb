# -*- coding: utf-8 -*-
module DcmgrResource
  class Volume < Base
    def self.list(params = {})
      self.find(:all,:params => params)
    end
  
    def self.create(params)
      volume = self.new
      volume.volume_size = params[:volume_size]
      volume.snapshot_id = params[:snapshot_id]
      volume.storage_pool_id = params[:storage_pool_id]
      volume.save
      volume
    end

    def self.destroy(volume_id)
      self.delete(volume_id).body
    end
  
    def self.attach(volume_id, instance_id)
      @collection ||= self.collection_name
      self.collection_name = File.join(@collection,volume_id)
      result = self.put(:attach, {:volume_id => volume_id,:instance_id => instance_id})
      self.collection_name = @collection
      result.body
    end
  
    def self.detach(volume_id)
      @collection ||= self.collection_name
      self.collection_name = File.join(@collection,volume_id)
      result = self.put(:detach, {:volume_id => volume_id})
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
