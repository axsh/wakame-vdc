# -*- coding: utf-8 -*-

module Dcmgr
  module EdgeNetworking
    module Tasks

      class AcceptArpBroadcast < Task
        include Dcmgr::EdgeNetworking::Netfilter
        attr_accessor :hva_ip

        def initialize(enable_logging = false, log_prefix = nil)
          super()

          rule = "-p ARP --arp-mac-dst 00:00:00:00:00:00 --dst ff:ff:ff:ff:ff:ff" +
                 " #{EbtablesRule.log_arp(log_prefix) if enable_logging} -j ACCEPT"

          # Allow broadcast from the host
          self.rules << EbtablesRule.new(:filter, :output, :arp, :outgoing, rule)
        end
      end

    end
  end
end
