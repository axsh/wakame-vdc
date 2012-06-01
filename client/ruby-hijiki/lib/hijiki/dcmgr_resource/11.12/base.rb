# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1112

  @debug = false

  class << self
    attr_accessor :debug
  end
  
  class Base < Hijiki::DcmgrResource::Base

    self.prefix = '/api/11.12/'

    def total
      attributes['total']
    end
  end

  module ListTranslateMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def instantiate_record(record, prefix_options = {})
        record['total'] = record.delete('owner_total')
        super(record, prefix_options)
      end
    end
  end
end
