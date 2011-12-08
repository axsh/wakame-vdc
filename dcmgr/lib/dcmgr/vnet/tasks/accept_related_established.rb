# -*- coding: utf-8 -*-

module Dcmgr
  module Vnet
    module Tasks
    
      # Accept related and established connections for tco
      class AcceptTcpRelatedEstablished < Task
        def initialize
          super()
          self.rules << IptablesRule.new(:filter,:forward,:tcp,:incoming,"-m state --state RELATED,ESTABLISHED -p tcp -j ACCEPT")
        end
      end
      
      # Accept related and established connections for icmp
      class AcceptIcmpRelatedEstablished < Task
        def initialize
          super()
          self.rules << IptablesRule.new(:filter,:forward,:icmp,:incoming,"-m state --state RELATED,ESTABLISHED -p icmp -j ACCEPT")
        end
      end
      
      # Accept established connections for any udp
      class AcceptUdpEstablished < Task
        def initialize
          super()
          self.rules << IptablesRule.new(:filter,:forward,:udp,:incoming,"-m state --state ESTABLISHED -p udp -j ACCEPT")
        end
      end
    
      # Accept related and established connaction for any protocol
      class AcceptRelatedEstablished < Task
        def initialize
          super()
          self.rules << IptablesRule.new(:filter,:forward,nil,:incoming,"-m state --state RELATED,ESTABLISHED -j ACCEPT")
        end
      end
    
    end
  end
end
