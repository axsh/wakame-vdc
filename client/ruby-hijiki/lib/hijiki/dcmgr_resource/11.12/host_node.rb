# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1112
  class HostNode < Base
    include Hijiki::DcmgrResource::ListMethods
    include ListTranslateMethods
  end

  HostNode.preload_resource('Result', Module.new {
    def node_id
      nil
    end
  })
end
