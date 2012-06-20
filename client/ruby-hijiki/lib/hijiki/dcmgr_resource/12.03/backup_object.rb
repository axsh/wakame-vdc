# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class BackupObject < Base

    module ClassMethods
      def list(params = {})
        self.find(:all,:params => params.merge({:state=>'alive_with_deleted'}))
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
        self.find(account_id).get(:status)
      end
    end
    extend ClassMethods
    
  end
end
