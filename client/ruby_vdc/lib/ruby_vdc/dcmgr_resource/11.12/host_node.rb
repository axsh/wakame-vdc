# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class HostNode < Base
    def self.list(params = {})
      self.find(:all,:params => params)
    end
    
    def self.show(host_node_id)
      self.get(host_node_id)
    end
  end

  HostNode.preload_resource('Result', Module.new {
    def node_id
      nil
    end
  })
end
