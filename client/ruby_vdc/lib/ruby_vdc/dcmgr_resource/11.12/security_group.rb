# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class SecurityGroup < Base
    include DcmgrResource::ListMethods
    include ListTranslateMethods
    include DcmgrResource::V1203::SecurityGroupMethods
  end
end
