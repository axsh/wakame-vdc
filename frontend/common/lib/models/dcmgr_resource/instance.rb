module Frontend::Models
  module DcmgrResource
    class Instance < Base
      def self.list(params = {})
        self.find(:all,:params => params)
      end
    end
  end
end