# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class HostNode < Base
    include DcmgrResource::ListMethods
    include ListTranslateMethods
  end

  HostNode.preload_resource('Result', Module.new {
    def node_id
      nil
    end
  })
end
