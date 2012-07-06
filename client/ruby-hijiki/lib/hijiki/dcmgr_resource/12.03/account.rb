# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Account < Base
    def usage
      self.get(:usage)
    end
  end
end
