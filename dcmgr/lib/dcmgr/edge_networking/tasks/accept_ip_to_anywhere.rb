# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      # Allows any outgoing IP layer traffic from the instance to pass through
      class AcceptIpToAnywhere < Task
        include Dcmgr::EdgeNetworking::Netfilter
        def initialize
          super()
          self.rules << IptablesRule.new(:filter,:forward,nil,:outgoing,"-j ACCEPT")
        end
      end

    end
  end
end
