# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Drop all incoming IP layer traffic
      class DropIpFromAnywhere < Task
        include Dcmgr::VNet::Netfilter
        def initialize
          super()
          self.rules << IptablesRule.new(:filter,:forward,nil,:incoming,"-j DROP")
        end
      end

    end
  end
end
