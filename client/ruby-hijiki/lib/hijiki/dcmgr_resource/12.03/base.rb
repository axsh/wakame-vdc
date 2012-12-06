# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203

  @debug = false

  class << self
    attr_accessor :debug
  end

  class Base < Hijiki::DcmgrResource::Common::Base

    self.prefix = '/api/12.03/'

    def total
      attributes['total']
    end
  end
end
