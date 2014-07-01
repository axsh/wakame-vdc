# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      class AcceptAllDNS < Task
        include Dcmgr::VNet::Netfilter
        def initialize()
          super()
          # Allow DNS traffic to take place
          self.rules << IptablesRule.new(:filter,:forward,:udp,:outgoing,"-p udp --dport 53 -j ACCEPT")
          self.rules << IptablesRule.new(:filter,:forward,:udp,:incoming,"-p udp --dport 53 -j ACCEPT")
        end
      end

    end
  end
end
