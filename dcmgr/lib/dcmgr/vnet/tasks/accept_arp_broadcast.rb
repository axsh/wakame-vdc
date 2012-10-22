# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      class AcceptArpBroadcast < Task
        include Dcmgr::VNet::Netfilter
        attr_accessor :hva_ip

        def initialize(hva_ip,enable_logging = false,log_prefix = nil)
          super()
          self.hva_ip = hva_ip

          # Allow broadcast from the network
          self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-mac-dst 00:00:00:00:00:00 #{EbtablesRule.log_arp(log_prefix) if enable_logging} -j ACCEPT")
          # Allow broadcast from the host
          self.rules << EbtablesRule.new(:filter,:output,:arp,:outgoing,"--protocol arp --arp-ip-src=#{self.hva_ip} #{EbtablesRule.log_arp(log_prefix) if enable_logging} --arp-mac-dst 00:00:00:00:00:00 -j ACCEPT")
        end
      end

    end
  end
end
