# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1112
  class VolumeSnapshot < Base
    include Hijiki::DcmgrResource::ListMethods
    include ListTranslateMethods
    include Hijiki::DcmgrResource::V1203::VolumeSnapshotMethods
  end

  VolumeSnapshot.preload_resource('Result', Module.new {
    def storage_node
      nil
    end
  })
end
