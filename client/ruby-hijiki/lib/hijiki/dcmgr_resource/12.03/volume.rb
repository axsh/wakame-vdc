# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Volume < Base

    module ClassMethods
      def list(params = {})
        self.find(:all,:params => params.merge({:state=>'alive_with_deleted'}))
      end
      
      def show(uuid)
        self.get(uuid)
      end

      def create(params)
        volume = self.new
        volume.volume_size = params[:volume_size]
        volume.backup_object_id = params[:backup_object_id]
        volume.display_name = params[:display_name]
        volume.save
        volume
      end

      def destroy(volume_id)
        self.delete(volume_id).body
      end
      
      def update(volume_id, params)
	self.put(volume_id,params).body
      end

      def attach(volume_id, instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,volume_id)
        result = self.put(:attach, {:volume_id => volume_id,:instance_id => instance_id})
        self.collection_name = @collection
        result.body
      end
      
      def detach(volume_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,volume_id)
        result = self.put(:detach, {:volume_id => volume_id})
        self.collection_name = @collection
        result.body
      end

      def status(account_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,account_id)
        result = self.get(:status)
        self.collection_name = @collection
        result
      end

      def backup(volume_id, params={})
        params = params.select {|k,v| [:display_name, :description].member?(k.to_sym) }
        result = self.find(volume_id).put(:backup, params)
        result.body
      end
    end
    extend ClassMethods
    
  end
end
