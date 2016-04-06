# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      # Drop all incoming IP layer traffic
      class DropIpFromAnywhere < Task
        include Dcmgr::EdgeNetworking::Netfilter
        def initialize
          super()
          self.rules << IptablesRule.new(:filter,:forward,nil,:incoming,"-j DROP")
        end
      end

    end
  end
end
