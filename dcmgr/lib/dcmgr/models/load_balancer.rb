# -*- coding: utf-8 -*-

module Dcmgr::Models
  class LoadBalancer < AccountResource
    taggable 'lb'
    one_to_one :instance, :class=>Instance, :key => :id

    class RequestError < RuntimeError; end
    
    def state
      @state = self.instance.state
    end

    def status
      @status = self.instance.status
    end
      
  end
end
