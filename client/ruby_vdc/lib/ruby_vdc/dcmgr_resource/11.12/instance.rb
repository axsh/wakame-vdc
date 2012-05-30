# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class Instance < Base
    include DcmgrResource::ListMethods
    include ListTranslateMethods
    include DcmgrResource::V1203::InstanceMethods
  end
end
