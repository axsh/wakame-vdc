# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      # Allow GARP from gateway device when it fails over to
      # slave device/node.
      # 
      # Note: this rule needs to be installed before the line of
      # anti-spoofing rules:
      #   DropIpSpoofing, DropARPSpoofing
      class AcceptGARPFromGateway < Task
        include Dcmgr::VNet::Netfilter
        attr_accessor :gw_ip

        def initialize(gw_ip,enable_logging = false,log_prefix = nil)
          super()
          self.gw_ip = gw_ip
          self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-gratuitous --arp-ip-src=#{self.gw_ip} #{EbtablesRule.log_arp(log_prefix) if enable_logging} -j ACCEPT")
        end
      end

    end
  end
end
