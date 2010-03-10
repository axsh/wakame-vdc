module Dcmgr
  module RestModels::Private
    class Instance
      include Dcmgr::RestModels::Base
      model Models::Instance
      allow_keys :status
      
      public_action_withid :get do
        get
      end
      
      public_action_withid :put do
        obj = model[uuid]
        req_hash = request
        req_hash.delete :id
        
        allow_keys.each{|key|
          if key == :status
            obj.status = req_hash[key]
            obj.status_updated_at = Time.now
            
          else req_hash.key?(key)
            obj.send('%s=' % key, req_hash[key])
          end
        }
        obj.save
      end
    end
  end
end
