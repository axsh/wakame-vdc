# -*- coding: utf-8 -*-
module DcmgrResource::V1203

  @debug = false

  class << self
    attr_accessor :debug
  end
  
  class Base < DcmgrResource::Base

    self.prefix = '/api/12.03/'

    def total
      attributes['total']
    end
  end
end
