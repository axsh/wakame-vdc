# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Accept ARP Reply to the instance from same link layer segment.
      # this rule should appear in earlier line.
      class AcceptARPReply < Task
        include Dcmgr::VNet::Netfilter

        def initialize(ip,macaddr,enable_logging = false,log_prefix = nil)
          super()
          # Allow ARP reply has correct IP & MAC address pair in
          # ARP destination field.
          self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-opcode Reply --arp-ip-dst=#{ip} --arp-mac-dst=#{macaddr} #{EbtablesRule.log_arp(log_prefix) if enable_logging} -j ACCEPT")
        end
      end

    end
  end
end
