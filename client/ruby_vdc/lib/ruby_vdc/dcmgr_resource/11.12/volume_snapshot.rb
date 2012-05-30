# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class VolumeSnapshot < Base
    include DcmgrResource::ListMethods
    include ListTranslateMethods
    include DcmgrResource::V1203::VolumeSnapshotMethods
  end

  VolumeSnapshot.preload_resource('Result', Module.new {
    def storage_node
      nil
    end
  })
end
