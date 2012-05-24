# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class Volume < Base
    include DcmgrResource::ListMethods
    include DcmgrResource::V1203::VolumeMethods
  end
end
