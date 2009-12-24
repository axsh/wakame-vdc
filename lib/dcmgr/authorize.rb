
module Dcmgr
  module Rolls
    class InstanceShutdownRoll
      def target
        Instance
      end
      
      def enable?
        true
      end
    end
  end

  # auth target is image or user
  def evalute(user, target, action)
    
  end
end
