module Dcmgr
  module Web
    class Public < Base
      helpers { include Dcmgr::UUIDAuthorizeHelpers }

      public_crud RestModels::Public::FrontendServiceUser
      
      public_crud RestModels::Public::Account
      public_crud RestModels::Public::User
      public_crud RestModels::Public::KeyPair
      
      public_crud RestModels::Public::NameTag
      public_crud RestModels::Public::AuthTag
      public_crud RestModels::Public::TagAttribute
      
      public_crud RestModels::Public::Instance

      public_crud RestModels::Public::PhysicalHost
      public_crud RestModels::Public::HvController
      
      public_crud RestModels::Public::ImageStorage
      public_crud RestModels::Public::ImageStorageHost

      public_crud RestModels::Public::LocationGroup
      
      get '/' do
        'startup dcmgr'
      end
    end
  end
end
