# -*- coding: utf-8 -*-

module Dcmgr
  module Vnet
    module Tasks
    
      # Drop all incoming IP layer traffic
      class DropIpFromAnywhere < Task
        def initialize
          super()
          self.rules << IptablesRule.new(:filter,:forward,nil,:incoming,"-j DROP")
        end
      end
    
    end
  end
end
