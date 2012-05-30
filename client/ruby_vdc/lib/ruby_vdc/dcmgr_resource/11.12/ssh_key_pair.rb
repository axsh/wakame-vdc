# -*- coding: utf-8 -*-
module DcmgrResource::V1112
  class SshKeyPair < Base
    include DcmgrResource::ListMethods
    include ListTranslateMethods
    include DcmgrResource::V1203::SshKeyPairMethods
  end
end
