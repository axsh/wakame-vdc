# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class VolumeSnapshot < Base
    include DcmgrResource::ListMethods
    include DcmgrResource::V1203::VolumeSnapshotMethods
  end
end
