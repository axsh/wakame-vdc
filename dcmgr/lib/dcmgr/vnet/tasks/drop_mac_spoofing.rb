# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Disables instances from spoofing another mac address
      class DropMacSpoofing < Task
        include Dcmgr::VNet::Netfilter
        attr_accessor :mac
        attr_accessor :enable_logging
        attr_accessor :log_prefix

        def initialize(mac,enable_logging,log_prefix)
        super()
        self.mac = mac
        self.enable_logging = enable_logging
        self.log_prefix = log_prefix

        # Prevent spoofing to the outside world
        self.rules << EbtablesRule.new(:filter,:forward,:arp,:outgoing,"--protocol arp --arp-mac-src ! #{self.mac} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
        # Prevent spoofing to the host
        self.rules << EbtablesRule.new(:filter,:input,:arp,:outgoing,"--protocol arp --arp-mac-src ! #{self.mac} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
        # Prevent spoofing from the host
        self.rules << EbtablesRule.new(:filter,:output,:arp,:incoming,"--protocol arp --arp-mac-dst ! #{self.mac} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
        end
      end

    end
  end
end
