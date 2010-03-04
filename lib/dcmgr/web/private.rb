module Dcmgr::Web
  class Private < Base
    helpers { include Dcmgr::NoAuthorizeHelpers }
    public_crud PrivateInstance
    
    get '/' do
      'startup dcmgr. private mode'
    end
  end
end
