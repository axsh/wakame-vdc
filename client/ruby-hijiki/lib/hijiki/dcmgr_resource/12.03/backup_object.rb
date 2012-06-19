# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  module BackupObjectMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def list(params = {})
        data = self.find(:all, :params => params)
      end

      def show(uuid)
        self.get(uuid)
      end
      
      def destroy(backup_object_id)
        self.delete(backup_object_id).body
      end
      
      def update(backup_object_id,params)
        self.put(backup_object_id,params).body
      end

      def status(account_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,account_id)
        result = self.get(:status)
        self.collection_name = @collection
        result
      end
    end    
  end

  class BackupObject < Base
    include BackupObjectMethods
  end
end
