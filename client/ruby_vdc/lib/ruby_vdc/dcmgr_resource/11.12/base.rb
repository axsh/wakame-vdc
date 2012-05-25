# -*- coding: utf-8 -*-
module DcmgrResource::V1112

  @debug = false

  class << self
    attr_accessor :debug
  end
  
  class Base < DcmgrResource::Base

    self.prefix = '/api/11.12/'

    def total
      attributes['owner_total']
    end

    def owner_total
      attributes['owner_total']
    end
  end
end
