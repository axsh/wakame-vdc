# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Disable instances from spoofing another ip address
      class DropIpSpoofing < Task
        include Dcmgr::VNet::Netfilter
        attr_accessor :ip
        attr_accessor :enable_logging
        attr_accessor :log_prefix

        def initialize(ip,enable_logging,log_prefix)
        super()
        self.ip = ip
        self.enable_logging = enable_logging
        self.log_prefix = log_prefix

        # Prevent spoofing to the outside world
        self.rules << EbtablesRule.new(:filter,:forward,:arp,:outgoing,"--protocol arp --arp-ip-src ! #{self.ip} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
        # Prevent spoofing to the host
        self.rules << EbtablesRule.new(:filter,:input,:arp,:outgoing,"--protocol arp --arp-ip-src ! #{self.ip} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")

        # Prevent the host from spoofing to the instance
        self.rules << EbtablesRule.new(:filter,:output,:arp,:incoming,"--protocol arp --arp-ip-dst ! #{self.ip} #{EbtablesRule.log_arp(self.log_prefix) if self.enable_logging} -j DROP")
        end
      end

    end
  end
end
