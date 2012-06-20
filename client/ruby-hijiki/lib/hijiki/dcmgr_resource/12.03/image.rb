# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Image < Base

    module ClassMethods
      def list(params = {})
        self.find(:all,:params => params.merge({:state=>'alive_with_deleted'}))
      end
      
      def show(uuid)
        self.get(uuid)
      end
      
      def update(uuid,params)
        self.put(uuid,params).body
      end
    end
    extend ClassMethods
    
  end
end
