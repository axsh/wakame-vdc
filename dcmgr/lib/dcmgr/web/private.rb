module Dcmgr
  module Web
    class Private < Base
      helpers { include NoAuthorizeHelpers }

      include RestModels::Private
      public_crud Instance
    
      get '/' do
        'startup dcmgr. private mode'
      end
    end
  end
end
