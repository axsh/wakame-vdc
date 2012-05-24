# -*- coding: utf-8 -*-
module DcmgrResource::V1203
  class Instance < Base
    include DcmgrResource::ListMethods

    def self.create(params)
      instance = self.new
      instance.image_id = params[:image_id]
      instance.instance_spec_id = params[:instance_spec_id]
      instance.host_pool_id = params[:host_pool_id]
      instance.host_name = params[:host_name]
      instance.user_data = params[:user_data]
      instance.security_groups = params[:security_groups]
      instance.ssh_key_id = params[:ssh_key]
      instance.save
      instance
    end
    
    def self.destroy(instance_id)
      self.delete(instance_id).body
    end
    
    def self.reboot(instance_id)
      @collection ||= self.collection_name
      self.collection_name = File.join(@collection,instance_id)
      result = self.put(:reboot)
      self.collection_name = @collection
      result.body
    end

    def self.start(instance_id)
      @collection ||= self.collection_name
      self.collection_name = File.join(@collection,instance_id)
      result = self.put(:start)
      self.collection_name = @collection
      result.body
    end

    def self.stop(instance_id)
      @collection ||= self.collection_name
      self.collection_name = File.join(@collection,instance_id)
      result = self.put(:stop)
      self.collection_name = @collection
      result.body
    end
    
  end
end
