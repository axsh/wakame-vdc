# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Tasks

      class AcceptARPFromGateway < Task
        include Dcmgr::VNet::Netfilter
        attr_accessor :gw_ip

        def initialize(gw_ip,ip,enable_logging = false,log_prefix = nil)
          super()
          self.gw_ip = gw_ip
          # Allow broadcast from the gateway
          self.rules << EbtablesRule.new(:filter,:forward,:arp,:incoming,"--protocol arp --arp-opcode Request --arp-ip-src=#{self.gw_ip} --arp-ip-dst=#{ip} #{EbtablesRule.log_arp(log_prefix) if enable_logging} -j ACCEPT")
        end
      end

    end
  end
end
