# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  module ImageMethods
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def update(uuid,params)
        self.put(uuid,params).body
      end
    end
  end

  class Image < Base
    include Hijiki::DcmgrResource::ListMethods
    include ImageMethods
  end
end
