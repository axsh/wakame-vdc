# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LoadBalancer < AccountResource
    taggable 'lb'

    one_to_one :instance
    class RequestError < RuntimeError; end
    
  end
end
