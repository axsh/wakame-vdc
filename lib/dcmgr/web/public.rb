module Dcmgr
  module Web
    class Public < Base
      helpers { include Dcmgr::UUIDAuthorizeHelpers }
      include RestModels::Public

      public_crud FrontendServiceUser
      
      public_crud Account
      public_crud User
      public_crud KeyPair
      
      public_crud NameTag
      public_crud AuthTag
      public_crud TagAttribute
      
      public_crud Instance

      public_crud PhysicalHost
      public_crud HvController
      
      public_crud ImageStorage
      public_crud ImageStorageHost

      public_crud Log
      public_crud AccountLog

      public_crud LocationGroup
      
      get '/' do
        'startup dcmgr'
      end
    end
  end
end
