# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Image < Base

    module ClassMethods
      include Hijiki::DcmgrResource::Common::ListMethods::ClassMethods

      def list(params = {})
        super(params.merge({:state=>'alive_with_deleted'}))
      end
      
      def update(uuid,params)
        self.put(uuid,params).body
      end
    end
    extend ClassMethods
    
  end
end
